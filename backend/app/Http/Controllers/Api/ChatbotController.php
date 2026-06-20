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
            'image' => 'nullable|image|max:10240',
        ]);

        $userId = $request->user()?->id;

        // Handle image upload if present
        $imagePath = null;
        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('chatbot', 'public');
        }

        // 1. Save user message into chatbot_sessions
        ChatbotSession::create([
            'user_id' => $userId,
            'session_id' => $validated['session_id'],
            'message' => $validated['message'],
            'image_path' => $imagePath,
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
     * Get all chat sessions for the authenticated user.
     */
    public function getSessions(Request $request)
    {
        $userId = $request->user()?->id;
        if (!$userId) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        // Group by session_id and find first user message & last update time
        $sessions = ChatbotSession::where('user_id', $userId)
            ->selectRaw('session_id, min(created_at) as started_at, max(created_at) as updated_at')
            ->groupBy('session_id')
            ->orderBy('updated_at', 'desc')
            ->get();

        $formattedSessions = [];
        foreach ($sessions as $session) {
            $firstMessage = ChatbotSession::where('session_id', $session->session_id)
                ->where('role', 'user')
                ->orderBy('id', 'asc')
                ->first();

            $title = $firstMessage ? Str::limit($firstMessage->message, 35) : 'New Agricultural Conversation';

            $formattedSessions[] = [
                'session_id' => $session->session_id,
                'title' => $title,
                'started_at' => $session->started_at,
                'updated_at' => $session->updated_at,
            ];
        }

        return response()->json([
            'success' => true,
            'sessions' => $formattedSessions,
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
                    'image_path' => $row->image_path,
                ];
            })
            ->values()
            ->toArray();
    }
}
