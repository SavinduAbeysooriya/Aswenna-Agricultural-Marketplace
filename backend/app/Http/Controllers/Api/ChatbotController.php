<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatbotSession;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class ChatbotController extends Controller
{
    /**
     * Create a new chat session.
     */
    public function createSession(Request $request)
    {
        $sessionId = Str::random(12);

        return response()->json([
            'success' => true,
            'session_id' => $sessionId,
        ], 201);
    }

    /**
     * Get all messages for a session.
     */
    public function getSessionMessages(Request $request, $sessionId)
    {
        $messages = $this->formatSessionMessages($sessionId);

        return response()->json([
            'session_id' => $sessionId,
            'messages' => $messages,
        ]);
    }

    /**
     * Send a message and get the AI reply.
     */
    public function sendMessage(Request $request)
    {
        $validated = $request->validate([
            'session_id' => 'required|string',
            'message' => 'required|string',
        ]);

        $userId = $request->user()?->id;

        // 1. Save user message into chatbot_sessions
        ChatbotSession::create([
            'user_id' => $userId,
            'session_id' => $validated['session_id'],
            'message' => $validated['message'],
            'response' => null,
            'role' => 'user',
        ]);

        // 2. Call Python RAG AI API
        $aiAnswer = null;
        try {
            $response = Http::timeout(15)->post('http://127.0.0.1:8000/chat', [
                'question' => $validated['message']
            ]);

            if ($response->successful()) {
                $aiAnswer = $response->json('answer');
            }
        } catch (\Exception $e) {
            // Silently handle fallback
        }

        // If Python AI is offline or returns an empty answer, use fallback
        if (empty($aiAnswer)) {
            $aiAnswer = "I'm having trouble connecting to my agricultural knowledge base right now. Please verify your connection or try again shortly!";
        }

        // 3. Save AI response into chatbot_sessions
        ChatbotSession::create([
            'user_id' => $userId,
            'session_id' => $validated['session_id'],
            'message' => null,
            'response' => $aiAnswer,
            'role' => 'assistant',
        ]);

        // 4. Return the full updated session conversation
        return response()->json([
            'session_id' => $validated['session_id'],
            'messages' => $this->formatSessionMessages($validated['session_id']),
        ]);
    }

    /**
     * Helper to retrieve and format all messages for a session.
     */
    private function formatSessionMessages($sessionId)
    {
        return ChatbotSession::where('session_id', $sessionId)
            ->orderBy('id', 'asc')
            ->get()
            ->map(function ($row) {
                return [
                    'role' => $row->role,
                    'message' => $row->role === 'user' ? $row->message : $row->response,
                ];
            })
            ->values()
            ->toArray();
    }
}
