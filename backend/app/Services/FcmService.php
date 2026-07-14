<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    protected string $projectId = 'aswenna-7fde5';
    protected string $serviceAccountPath;

    public function __construct()
    {
        $this->serviceAccountPath = storage_path('app/firebase-service-account.json');
    }

    /**
     * Send a push notification to a single FCM device token.
     */
    public function sendPush(string $fcmToken, string $title, string $body, array $data = []): bool
    {
        try {
            $accessToken = $this->getAccessToken();
            if (!$accessToken) {
                Log::error('[FCM] Failed to obtain OAuth2 access token.');
                return false;
            }

            $url = "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send";

            $payload = [
                'message' => [
                    'token' => $fcmToken,
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'android' => [
                        'priority' => 'HIGH',
                        'notification' => [
                            'channel_id' => 'aswenna_notifications',
                            'sound' => 'default',
                            'default_vibrate_timings' => true,
                        ],
                    ],
                    'apns' => [
                        'payload' => [
                            'aps' => [
                                'alert' => ['title' => $title, 'body' => $body],
                                'sound' => 'default',
                                'badge' => 1,
                            ],
                        ],
                    ],
                    'data' => array_map('strval', array_merge($data, ['click_action' => 'FLUTTER_NOTIFICATION_CLICK'])),
                ],
            ];

            $response = Http::withToken($accessToken)
                ->withHeaders(['Content-Type' => 'application/json'])
                ->post($url, $payload);

            if ($response->successful()) {
                Log::info("[FCM] Push sent to token ...".substr($fcmToken, -8).": [$title]");
                return true;
            } else {
                Log::error("[FCM] Push failed: " . $response->body());
                return false;
            }
        } catch (\Exception $e) {
            Log::error("[FCM] Exception: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Generate a short-lived OAuth2 access token using the service account JWT.
     */
    protected function getAccessToken(): ?string
    {
        try {
            $serviceAccount = json_decode(file_get_contents($this->serviceAccountPath), true);

            $now = time();
            $exp = $now + 3600;

            $header = $this->base64url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            $claims = $this->base64url(json_encode([
                'iss'   => $serviceAccount['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud'   => 'https://oauth2.googleapis.com/token',
                'exp'   => $exp,
                'iat'   => $now,
            ]));

            $signingInput = "$header.$claims";

            $privateKey = $serviceAccount['private_key'];
            $pkeyId = openssl_pkey_get_private($privateKey);

            openssl_sign($signingInput, $signature, $pkeyId, OPENSSL_ALGO_SHA256);

            $jwt = "$signingInput." . $this->base64url($signature);

            $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion'  => $jwt,
            ]);

            if ($response->successful()) {
                return $response->json('access_token');
            }

            Log::error('[FCM] Token exchange failed: ' . $response->body());
            return null;
        } catch (\Exception $e) {
            Log::error('[FCM] JWT generation error: ' . $e->getMessage());
            return null;
        }
    }

    private function base64url(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
