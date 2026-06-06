<?php

use Illuminate\Support\Facades\DB;
use Livewire\Component;

new class extends Component
{
    public int $farmerId;
    public ?string $selectedSessionId = null;
    public string $search = '';

    public function selectSession(string $sessionId): void
    {
        $this->selectedSessionId = $sessionId;
    }

    public function deselectSession(): void
    {
        $this->selectedSessionId = null;
    }

    private function getSessions()
    {
        $search = trim($this->search);

        // Get all unique sessions for this user
        $sessions = DB::table('chatbot_sessions')
            ->where('user_id', $this->farmerId)
            ->select('session_id', DB::raw('MIN(created_at) as started_at'), DB::raw('COUNT(*) as total_rows'))
            ->groupBy('session_id')
            ->orderByDesc('started_at')
            ->get();

        return $sessions->map(function ($session) use ($search) {
            // Retrieve first user message or first message of any role
            $firstMsg = DB::table('chatbot_sessions')
                ->where('session_id', $session->session_id)
                ->orderBy('id', 'asc')
                ->first();

            $preview = 'Empty conversation';
            if ($firstMsg) {
                $preview = $firstMsg->message ?: $firstMsg->response ?: 'Empty conversation';
            }

            // Check if search matches preview or session id
            if ($search !== '' && 
                stripos($preview, $search) === false && 
                stripos($session->session_id, $search) === false) {
                return null;
            }

            return [
                'session_id' => $session->session_id,
                'started_at' => $session->started_at,
                'preview' => $preview,
                'total_rows' => $session->total_rows,
            ];
        })->filter()->values();
    }

    private function getSelectedSessionMessages()
    {
        if (!$this->selectedSessionId) {
            return [];
        }

        return DB::table('chatbot_sessions')
            ->where('session_id', $this->selectedSessionId)
            ->orderBy('id', 'asc')
            ->get()
            ->flatMap(function ($row) {
                $messages = [];
                // If it is a user role row with a message
                if ($row->role === 'user' && !empty($row->message)) {
                    $messages[] = [
                        'role' => 'user',
                        'content' => $row->message,
                        'created_at' => $row->created_at,
                    ];
                }
                // If it has a response (either assistant role, or user role with seeded response)
                if (!empty($row->response)) {
                    $messages[] = [
                        'role' => 'assistant',
                        'content' => $row->response,
                        'created_at' => $row->created_at,
                    ];
                }
                // If it is an assistant role but response is empty but message is not empty (defensive)
                if ($row->role === 'assistant' && empty($row->response) && !empty($row->message)) {
                    $messages[] = [
                        'role' => 'assistant',
                        'content' => $row->message,
                        'created_at' => $row->created_at,
                    ];
                }
                return $messages;
            })
            ->toArray();
    }

    public function render()
    {
        return $this->view([
            'sessions' => $this->getSessions(),
            'messages' => $this->getSelectedSessionMessages(),
        ]);
    }

    public function formatMarkdown(string $text, bool $isUser = false): string
    {
        $html = htmlspecialchars($text, ENT_QUOTES, 'UTF-8');
        
        $boldClass = $isUser ? 'font-black text-white' : 'font-extrabold text-slate-900';
        $italicClass = $isUser ? 'italic text-emerald-100' : 'italic text-slate-800';
        
        $html = preg_replace('/\*\*(.*?)\*\*/', '<strong class="' . $boldClass . '">$1</strong>', $html);
        $html = preg_replace('/##(.*?)##/', '<em class="' . $italicClass . '">$1</em>', $html);
        $html = preg_replace('/\*([^\*]+?)\*/', '<em class="' . $italicClass . '">$1</em>', $html);
        $html = preg_replace('/_([^_]+?)_/', '<em class="' . $italicClass . '">$1</em>', $html);
        
        $html = preg_replace('/^###\s+(.*?)$/m', '<h5 class="text-[11px] font-black uppercase tracking-wider text-emerald-800 mt-3 mb-1 block">$1</h5>', $html);
        $html = preg_replace('/^##\s+(.*?)$/m', '<h4 class="text-xs font-black text-slate-900 mt-4 mb-1.5 block">$1</h4>', $html);
        $html = preg_replace('/^#\s+(.*?)$/m', '<h3 class="text-sm font-black text-slate-900 mt-4 mb-2 block">$1</h3>', $html);
        
        $bulletColor = $isUser ? 'text-emerald-200' : 'text-emerald-500';
        $html = preg_replace('/^\-\s+(.*?)$/m', '<div class="flex items-start gap-1.5 ml-2.5 mt-1"><span class="' . $bulletColor . ' text-[10px] select-none">•</span><span class="flex-1">$1</span></div>', $html);
        $html = preg_replace('/^\*\s+(.*?)$/m', '<div class="flex items-start gap-1.5 ml-2.5 mt-1"><span class="' . $bulletColor . ' text-[10px] select-none">•</span><span class="flex-1">$1</span></div>', $html);
        
        $html = nl2br($html);
        $html = preg_replace('~<br\s*/{0,1}>\s*(<h[345]|<div class="flex)~i', '$1', $html);
        $html = preg_replace('~(</h[345]>|</div>)\s*<br\s*/{0,1}>~i', '$1', $html);
        
        return $html;
    }
};
?>

<div class="space-y-6">
    <div class="bg-white border border-slate-100 rounded-3xl shadow-sm overflow-hidden">
        
        <!-- Tab Sub-Header -->
        <div class="p-5 sm:p-6 border-b border-slate-100 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
                <h2 class="text-base font-extrabold text-slate-900 flex items-center gap-2">
                    <i class="fa-solid fa-robot text-emerald-600"></i> AI Chatbot Assistant History
                </h2>
                <p class="text-xs text-slate-500 font-medium mt-0.5">Audit dialogue trails, support sessions, and advisor inquiries exchanged with the Aswenna AI agent.</p>
            </div>
            
            <div wire:loading class="self-start md:self-auto text-xs font-extrabold text-emerald-700 bg-emerald-50 border border-emerald-100 rounded-full px-3 py-1">
                Syncing audit trails...
            </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-12 min-h-[480px]">
            
            <!-- Left Panel: Session Selector -->
            <div class="lg:col-span-4 border-r border-slate-100 flex flex-col bg-slate-50/20">
                <div class="p-4 border-b border-slate-100">
                    <div class="relative">
                        <i class="fa-solid fa-magnifying-glass absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 text-xs"></i>
                        <input wire:model.live.debounce.250ms="search" 
                            type="text" 
                            class="w-full rounded-xl border border-slate-200 bg-slate-50/50 pl-9 pr-4 py-2 text-xs font-semibold outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" 
                            placeholder="Search chats, prompts...">
                    </div>
                </div>

                <div class="overflow-y-auto max-h-[420px] divide-y divide-slate-100/60 custom-scrollbar flex-1">
                    @forelse($sessions as $sess)
                        @php
                            $isSelected = $selectedSessionId === $sess['session_id'];
                            $started = date('M d, Y • h:i A', strtotime($sess['started_at']));
                        @endphp
                        <button type="button" 
                            wire:click="selectSession('{{ $sess['session_id'] }}')" 
                            class="w-full text-left p-4 transition duration-150 flex flex-col gap-1.5 focus:outline-none hover:bg-slate-50/60 {{ $isSelected ? 'bg-emerald-50/40 border-l-4 border-emerald-600 hover:bg-emerald-50/40' : '' }}">
                            <div class="flex items-center justify-between">
                                <span class="text-[10px] font-black uppercase text-emerald-700 font-poppins">{{ $sess['session_id'] }}</span>
                                <span class="text-[9px] text-slate-400 font-bold">{{ $started }}</span>
                            </div>
                            <p class="text-xs font-semibold text-slate-700 line-clamp-2 leading-relaxed">
                                "{{ $sess['preview'] }}"
                            </p>
                        </button>
                    @empty
                        <div class="p-8 text-center text-slate-400">
                            <i class="fa-solid fa-comments text-2xl text-slate-200 mb-2"></i>
                            <p class="text-xs font-bold">No sessions found</p>
                        </div>
                    @endforelse
                </div>
            </div>

            <!-- Right Panel: Conversation Thread -->
            <div class="lg:col-span-8 flex flex-col bg-[#FAFBFD]/30 min-h-[350px]">
                @if($selectedSessionId)
                    <!-- Session Active Header -->
                    <div class="px-5 py-3.5 border-b border-slate-100 bg-white flex items-center justify-between shadow-sm">
                        <div class="flex items-center gap-2.5">
                            <div class="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse"></div>
                            <div>
                                <strong class="text-xs font-extrabold text-slate-900 font-poppins block">{{ $selectedSessionId }}</strong>
                                <span class="text-[9px] text-slate-400 font-medium">Dialogue Audit History Log</span>
                            </div>
                        </div>
                        <button type="button" 
                            wire:click="deselectSession" 
                            class="text-[10px] font-extrabold text-slate-400 hover:text-slate-600 uppercase flex items-center gap-1 focus:outline-none">
                            Close Chat <i class="fa-solid fa-xmark"></i>
                        </button>
                    </div>

                    <!-- Chat Bubbles Thread -->
                    <div class="flex-1 overflow-y-auto p-5 space-y-4 max-h-[380px] custom-scrollbar bg-slate-50/10">
                        @foreach($messages as $msg)
                            @php
                                $isUser = $msg['role'] === 'user';
                                $timestamp = date('h:i A', strtotime($msg['created_at']));
                            @endphp

                            <div class="flex {{ $isUser ? 'justify-end' : 'justify-start' }} items-start gap-2.5">
                                @if(!$isUser)
                                    <div class="w-7 h-7 rounded-full bg-emerald-50 border border-emerald-100 flex items-center justify-center shrink-0">
                                        <i class="fa-solid fa-robot text-emerald-600 text-[10px]"></i>
                                    </div>
                                @endif

                                <div class="max-w-[75%] flex flex-col gap-1">
                                    <div class="p-3.5 rounded-2xl text-xs leading-relaxed shadow-sm font-semibold {{ $isUser ? 'bg-emerald-600 text-white rounded-tr-none' : 'bg-white text-slate-700 border border-slate-100 rounded-tl-none' }}">
                                        {!! $this->formatMarkdown($msg['content'], $isUser) !!}
                                    </div>
                                    <span class="text-[9px] text-slate-400 {{ $isUser ? 'text-right' : 'text-left' }} px-1 font-bold">{{ $timestamp }}</span>
                                </div>

                                @if($isUser)
                                    <div class="w-7 h-7 rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center shrink-0">
                                        <i class="fa-solid fa-user text-slate-500 text-[10px]"></i>
                                    </div>
                                @endif
                            </div>
                        @endforeach
                    </div>

                @else
                    <!-- Placeholder Empty View -->
                    <div class="flex-1 flex flex-col items-center justify-center p-8 text-center bg-white/50">
                        <div class="w-16 h-16 rounded-3xl bg-slate-50 text-slate-300 flex items-center justify-center text-2xl shadow-inner mb-4">
                            <i class="fa-solid fa-message"></i>
                        </div>
                        <h4 class="text-xs font-extrabold text-slate-700 uppercase tracking-wide">Select Chat Session</h4>
                        <p class="text-[11px] text-slate-400 mt-1 max-w-sm">Click on any conversation session log on the left panel to review message transcripts exchanged with the AI agent.</p>
                    </div>
                @endif
            </div>

        </div>

    </div>
</div>
