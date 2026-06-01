<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Chat;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Exception;

class ChatMessageController extends Controller
{
    /**
     * GET /api/chats/{otherUserId}
     * Get all messages between authenticated user and another user.
     */
    public function getConversation(Request $request, $otherUserId)
    {
        $user = $request->user();

        // Mark incoming messages as read
        Chat::where('sender_id', $otherUserId)
            ->where('receiver_id', $user->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        $messages = Chat::where(function ($q) use ($user, $otherUserId) {
            $q->where('sender_id', $user->id)->where('receiver_id', $otherUserId);
        })->orWhere(function ($q) use ($user, $otherUserId) {
            $q->where('sender_id', $otherUserId)->where('receiver_id', $user->id);
        })
            ->orderBy('sent_at')
            ->get();

        return response()->json([
            'success'        => true,
            'messages'       => $messages,
            'current_user_id'=> $user->id,
        ], 200);
    }

    /**
     * POST /api/chats/send
     * Send a new text message.
     */
    public function sendMessage(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'receiver_id'  => 'required|integer|exists:users,id',
            'message_text' => 'required|string|max:2000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        try {
            $chat = Chat::create([
                'sender_id'    => $user->id,
                'receiver_id'  => $request->receiver_id,
                'type'         => 'text',
                'message_text' => $request->message_text,
                'is_read'      => false,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Message sent successfully.',
                'chat'    => $chat,
            ], 201);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to send message.',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/chats/conversations
     * Get list of all conversations (unique users the authenticated user has chatted with).
     */
    public function getConversations(Request $request)
    {
        $user = $request->user();

        $conversations = DB::table('chats')
            ->where('sender_id', $user->id)
            ->orWhere('receiver_id', $user->id)
            ->select(DB::raw('
                CASE
                    WHEN sender_id = ' . $user->id . ' THEN receiver_id
                    ELSE sender_id
                END as other_user_id,
                MAX(sent_at) as last_message_at,
                MAX(id) as last_chat_id
            '))
            ->groupBy(DB::raw('CASE WHEN sender_id = ' . $user->id . ' THEN receiver_id ELSE sender_id END'))
            ->orderByDesc('last_message_at')
            ->get();

        $result = [];
        foreach ($conversations as $conv) {
            $otherUser = DB::table('users')
                ->where('id', $conv->other_user_id)
                ->select('id', 'full_name', 'profile_picture_path')
                ->first();

            $lastMessage = Chat::find($conv->last_chat_id);
            $unreadCount = Chat::where('sender_id', $conv->other_user_id)
                ->where('receiver_id', $user->id)
                ->where('is_read', false)
                ->count();

            $result[] = [
                'other_user'    => $otherUser,
                'last_message'  => $lastMessage,
                'unread_count'  => $unreadCount,
            ];
        }

        return response()->json(['success' => true, 'conversations' => $result], 200);
    }
}
