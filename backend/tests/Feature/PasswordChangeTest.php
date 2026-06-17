<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class PasswordChangeTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test unauthenticated user cannot change password.
     */
    public function test_unauthenticated_user_cannot_change_password()
    {
        $response = $this->postJson('/api/user/change-password', [
            'current_password' => 'old_password',
            'new_password' => 'new_password123',
            'confirm_password' => 'new_password123',
        ]);

        $response->assertStatus(401);
    }

    /**
     * Test password can be changed successfully with valid data.
     */
    public function test_password_can_be_changed_successfully()
    {
        $user = User::factory()->create([
            'password' => 'old_password_123',
        ]);

        $response = $this->actingAs($user)
            ->postJson('/api/user/change-password', [
                'current_password' => 'old_password_123',
                'new_password' => 'new_password_456',
                'confirm_password' => 'new_password_456',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Password changed successfully.'
            ]);

        $user->refresh();
        $this->assertTrue(Hash::check('new_password_456', $user->password));
    }

    /**
     * Test validation fails when fields are missing.
     */
    public function test_change_password_validation_fails_when_fields_are_missing()
    {
        $user = User::factory()->create([
            'password' => 'old_password_123',
        ]);

        $response = $this->actingAs($user)
            ->postJson('/api/user/change-password', [
                'current_password' => '',
                'new_password' => '',
                'confirm_password' => '',
            ]);

        $response->assertStatus(422)
            ->assertJsonStructure([
                'success',
                'message',
                'errors' => [
                    'current_password',
                    'new_password',
                    'confirm_password',
                ]
            ]);
    }

    /**
     * Test validation fails when new password is same as current password.
     */
    public function test_change_password_fails_if_new_password_is_same_as_current()
    {
        $user = User::factory()->create([
            'password' => 'old_password_123',
        ]);

        $response = $this->actingAs($user)
            ->postJson('/api/user/change-password', [
                'current_password' => 'old_password_123',
                'new_password' => 'old_password_123',
                'confirm_password' => 'old_password_123',
            ]);

        $response->assertStatus(422)
            ->assertJsonStructure([
                'success',
                'message',
                'errors' => [
                    'new_password'
                ]
            ]);
    }

    /**
     * Test validation fails when confirm password does not match new password.
     */
    public function test_change_password_fails_if_confirm_password_does_not_match()
    {
        $user = User::factory()->create([
            'password' => 'old_password_123',
        ]);

        $response = $this->actingAs($user)
            ->postJson('/api/user/change-password', [
                'current_password' => 'old_password_123',
                'new_password' => 'new_password_456',
                'confirm_password' => 'different_confirm_password',
            ]);

        $response->assertStatus(422)
            ->assertJsonStructure([
                'success',
                'message',
                'errors' => [
                    'confirm_password'
                ]
            ]);
    }

    /**
     * Test verification fails when provided current password is incorrect.
     */
    public function test_change_password_fails_when_current_password_is_incorrect()
    {
        $user = User::factory()->create([
            'password' => 'old_password_123',
        ]);

        $response = $this->actingAs($user)
            ->postJson('/api/user/change-password', [
                'current_password' => 'incorrect_current_password',
                'new_password' => 'new_password_456',
                'confirm_password' => 'new_password_456',
            ]);

        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
                'message' => 'The provided current password does not match our records.'
            ]);
    }
}
