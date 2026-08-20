<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DigitalContractSeeder extends Seeder
{
    public function run(): void
    {
        $buyers = DB::table('users')->where('role', 'buyer')->orWhere('role', 'like', '%buyer%')->get();
        $farmer = DB::table('users')->where('role', 'farmer')->orWhere('role', 'like', '%farmer%')->first();
        $crop = DB::table('crops')->where('cropname', 'like', '%Chilli%')->orWhere('cropname', 'like', '%Green%')->first();

        $farmerId = $farmer ? $farmer->id : 1;
        $cropId = $crop ? $crop->id : 1;
        $cropName = $crop ? $crop->cropname : 'Green Chilli';

        foreach ($buyers as $buyer) {
            DB::table('digital_contracts')->updateOrInsert(
                [
                    'buyer_id' => $buyer->id,
                    'offer_code' => 'OFF-4412',
                ],
                [
                    'farmer_id' => $farmerId,
                    'crop_id' => $cropId,
                    'crop_name' => $cropName,
                    'quantity' => 1000.00,
                    'unit' => 'kg',
                    'initial_price_per_unit' => 350.00,
                    'counter_offer_price_per_unit' => 315.00,
                    'total_contract_value' => 315000.00,
                    'escrow_deposit_percent' => 20.00,
                    'escrow_deposit_amount' => 63000.00,
                    'status' => 'counter_offer_received',
                    'notes' => 'Farmer counter-offer accepted rate at LKR 315/kg for 1,000 kg bulk produce.',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }
    }
}
