<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatbotSession;
use Illuminate\Http\Request;

class ChatbotController extends Controller
{
    // Save full conversation when session ends
    public function store(Request $request)
    {
        $validated = $request->validate([
            'chat_title'        => 'nullable|string|max:255',
            'customer_rating'   => 'nullable|integer|min:1|max:5',
            'customer_feedback' => 'nullable|string',
            'messages'          => 'required|array|min:1',
            'messages.*.farmer_quiz' => 'required|string',
            'messages.*.bot_answer'  => 'nullable|string',
            'messages.*.order'       => 'required|integer|min:1',
            'messages.*.image_path'  => 'nullable|string',
            'messages.*.date_and_time' => 'required|string',
        ]);

        $farmerId = $request->user()->id;

        foreach ($validated['messages'] as $msg) {
            ChatbotSession::create([
                'farmer_id'         => $farmerId,
                'chat_title'        => $validated['chat_title'] ?? null,
                'farmer_quiz'       => $msg['farmer_quiz'],
                'bot_answer'        => $msg['bot_answer'] ?? null,
                'date_and_time'     => $msg['date_and_time'],
                'order'             => $msg['order'],
                'image_path'        => $msg['image_path'] ?? null,
                'is_ended'          => true,
                'customer_rating'   => $validated['customer_rating'] ?? null,
                'customer_feedback' => $validated['customer_feedback'] ?? null,
            ]);
        }

        return response()->json(['success' => true, 'message' => 'Chat session saved.'], 201);
    }

    // Get all chat messages for the authenticated farmer
    public function index(Request $request)
    {
        $sessions = ChatbotSession::where('farmer_id', $request->user()->id)
            ->orderBy('order')
            ->get();

        return response()->json(['success' => true, 'sessions' => $sessions]);
    }
}
