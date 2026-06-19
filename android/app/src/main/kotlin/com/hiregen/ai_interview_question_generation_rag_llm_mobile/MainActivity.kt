package com.hiregen.ai_interview_question_generation_rag_llm_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode

class MainActivity : FlutterActivity() {
    // Force TextureView + software rendering fallback for emulators with broken GPU drivers
    override fun getRenderMode(): RenderMode = RenderMode.texture
}
