const functions = require("firebase-functions");
const { defineSecret } = require("firebase-functions/params");
const express = require("express");
const cors = require("cors");
const axios = require("axios");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
admin.initializeApp();

const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
const APPLE_SHARED_SECRET = defineSecret("APPLE_SHARED_SECRET");

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: '5kb' }));

// JSONサイズ超過をキャッチ
app.use((err, req, res, next) => {
  if (err.type === 'entity.too.large') {
    return res.status(413).send({ errorCode: "TOO_LONG" });
  }
  next(err);
});

// レート制限（UID単位で1分間に最大60回）
const rateLimitMap = {};

app.post("/chat", async (req, res) => {
  const authHeader = req.headers.authorization || '';
  const idToken = authHeader.startsWith("Bearer ") ? authHeader.split("Bearer ")[1] : null;

  if (!idToken) {
    return res.status(401).send({ errorCode: "NO_TOKEN" });
  }

  let uid;
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    uid = decoded.uid;
  } catch (err) {
    console.error("❌ IDトークン検証失敗:", err);
    return res.status(401).send({ errorCode: "INVALID_TOKEN" });
  }

  // ✅ レート制限
  const now = Date.now();
  rateLimitMap[uid] = (rateLimitMap[uid] || []).filter(t => now - t < 60000);
  if (rateLimitMap[uid].length >= 60) {
    const oldest = rateLimitMap[uid][0];
    const retryAfterSec = Math.ceil((60000 - (now - oldest)) / 1000);
    res.set("Retry-After", retryAfterSec.toString());
    return res.status(429).send({ errorCode: "RATE_LIMIT" });
  }
  rateLimitMap[uid].push(now);

  // ✅ リクエスト内容の検証
  const userMessage = req.body.message;
  const userInput = req.body.userInput || "";

  if (!userMessage) {
    return res.status(400).send({ errorCode: "NO_MESSAGE" });
  }

  if (userInput.length > 100) {
    return res.status(400).send({ errorCode: "TOO_LONG" });
  }

  const requestId = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

  try {
    // リクエストから message（=userMessage）と model を取得、model がなければ gpt-3.5-turbo
    const { message: userMessage, model = "gpt-3.5-turbo" } = req.body;

    const response = await axios.post(
      "https://api.openai.com/v1/chat/completions",
      {
        model,
        messages: [
          { role: "system", content: "あなたは親切な英会話講師です。" },
          { role: "user",   content: userMessage },
        ],
      },
      {
        headers: {
          Authorization: `Bearer ${OPENAI_API_KEY.value()}`,
          "Content-Type": "application/json",
        },
      }
    );
    const reply = response.data.choices[0].message.content;
    res.status(200).send({ reply });
  } catch (error) {
    const openAiStatus = error.response?.status ?? null;
    const openAiError  = error.response?.data?.error ?? null;
    console.error("❌ OpenAIエラー", {
      requestId,
      uid,
      stage: "openai_chat",
      httpStatus: openAiStatus,
      openAiCode: openAiError?.code,
      openAiType: openAiError?.type,
      message: error.message,
      stack: error.stack,
    });
    res.status(500).send({
      errorCode: "SERVER_ERROR",
      stage: "openai_chat",
      requestId,
      message: openAiStatus === 401
        ? "OpenAI API key is invalid or expired"
        : openAiStatus === 429
        ? "OpenAI rate limit or quota exceeded"
        : "Upstream API error",
    });
  }
});

// テスト中は Sandbox のみを使う
const PRODUCTION_URL = "https://sandbox.itunes.apple.com/verifyReceipt";
// 実運用では本番用 → 21007 で Sandbox にフォールバックするために定義だけ残す
const SANDBOX_URL    = "https://buy.itunes.apple.com/verifyReceipt";

async function callVerify(url, body) {
  try {
    const res = await fetch(url, {
      method: "POST",
      body,
      headers: { "Content-Type": "application/json" },
    });
    const json = await res.json();
    return json;
  } catch (err) {
    console.error("🔥 callVerify failed for URL", url, err);
    throw err;
  }
}

exports.verifyReceipt = functions
  .region("asia-northeast1")
  .runWith({ secrets: [APPLE_SHARED_SECRET] })
  .https.onCall(async (data, context) => {
    console.log("⚡ verifyReceipt called, receiptData length:", data.receiptData?.length);
    console.log("receiptData startsWith:", data.receiptData.slice(0,50));

    const body = JSON.stringify({
      "receipt-data": data.receiptData,
      password: APPLE_SHARED_SECRET.value(),
    });
    console.log("→ Calling production verify with body length:", body.length);

    // ① 本番用＋ログ
    let json = await callVerify(PRODUCTION_URL, body);
    console.log("← Production response status:", json.status);

    // ② Sandbox 再試行＋ログ
    if (json.status === 21007) {
      console.log("→ Production returned 21007, retrying sandbox");
      json = await callVerify(SANDBOX_URL, body);
      console.log("← Sandbox response status:", json.status);
    }

    if (json.status !== 0) {
      console.error("✖️ Invalid receipt status:", json.status, json);
      throw new functions.https.HttpsError("internal", `Invalid receipt: ${json.status}`);
    }

    // レシート情報の存在チェック
    const infos = json.latest_receipt_info;
    console.log("📦 latest_receipt_info items:", infos?.length);
    if (!infos || !infos.length) {
      console.error("✖️ latest_receipt_info missing:", json);
      throw new functions.https.HttpsError("internal", "No latest_receipt_info");
    }

    // ③ 最終レシート情報
    const latest = infos.sort((a, b) =>
      Number(b.expires_date_ms) - Number(a.expires_date_ms)
    )[0];
    console.log("✅ Latest receipt info:", latest);

    return {
      productId: latest.product_id,
      purchaseDateMs: Number(latest.purchase_date_ms),
      expirationDateMs: Number(latest.expires_date_ms),
    };
  });


exports.api = functions
  .region('asia-northeast1')
  .runWith({ secrets: [OPENAI_API_KEY] })
  .https.onRequest(app);

// ============================================================
// ttsProxy – VOICEVOX TTS 中継 (gen2 onCall)
// ============================================================

const { onCall, HttpsError } = require("firebase-functions/v2/https");

const TTS_API_KEY = defineSecret("TTS_API_KEY");

const TTS_SPEAKER_MAP = {
  tumugi: "春日部つむぎ",
  kasumi: "四国めたん",
};

// メモリ内レート制限
const ttsRateLimitMap = new Map();

exports.ttsProxy = onCall(
  {
    region: "asia-northeast1",
    timeoutSeconds: 60,
    secrets: [TTS_API_KEY],
  },
  async (request) => {
    // 認証チェック
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const uid = request.auth.uid;

    // レート制限
    const now = Date.now();
    const timestamps = (ttsRateLimitMap.get(uid) || []).filter(
      (t) => now - t < 60000
    );

    if (timestamps.length >= 10) {
      const retryAfterSec = Math.ceil((60000 - (now - timestamps[0])) / 1000);
      throw new HttpsError("resource-exhausted", "Rate limit exceeded", {
        retryAfterSec,
      });
    }

    timestamps.push(now);
    ttsRateLimitMap.set(uid, timestamps);

    // 入力チェック
    const { text, character } = request.data;

    if (!text || typeof text !== "string" || text.trim() === "") {
      throw new HttpsError("invalid-argument", "text is required");
    }

    const speakerName =
      TTS_SPEAKER_MAP[character] ?? TTS_SPEAKER_MAP.tumugi;

    console.log(
      `[ttsProxy] uid=${uid} speaker=${speakerName} text="${text.slice(0, 40)}"`
    );

    // VPSへ中継
    try {
      const response = await axios.post(
        "https://tts.kawaiilang.com/tts",
        { text, speakerName },
        {
          headers: {
            "Content-Type": "application/json",
            "x-api-key": TTS_API_KEY.value(),
          },
          responseType: "arraybuffer",
          timeout: 30000,
        }
      );

      const audioBase64 = Buffer.from(response.data).toString("base64");

      console.log(
        `[ttsProxy] success uid=${uid} bytes=${response.data.byteLength}`
      );

      return {
        audioBase64,
        contentType: "audio/wav",
      };
    } catch (err) {
      console.error(`[ttsProxy] VPS error: ${err.message}`);
      throw new HttpsError("internal", "TTS request failed");
    }
  }
);
