<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;
use Exception;

class LandController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $lands = DB::table('lands')
            ->where('farmer_id', $user->id)
            ->orderByDesc('created_at')
            ->get()
            ->map(function ($land) {
                $land->land_images = json_decode($land->land_images ?? '[]', true) ?: [];
                $land->land_documents = json_decode($land->land_documents_paths_and_document_titles ?? '[]', true) ?: [];
                return $land;
            });

        return response()->json(['success' => true, 'lands' => $lands], 200);
    }

    public function store(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'size'           => 'required|numeric|min:0.01',
            'ownership_type' => 'required|string|in:owned,license,lease,government,other',
            'registration_number' => 'nullable|string|max:255',
            'latitude'       => 'nullable|numeric|between:-90,90',
            'longitude'      => 'nullable|numeric|between:-180,180',
            'notes'          => 'nullable|string|max:1000',
            'land_images.*'  => 'nullable|file|mimes:jpg,jpeg,png|max:5120',
            'land_document_files.*' => 'nullable|file|mimes:jpg,jpeg,png,pdf|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        DB::beginTransaction();
        try {
            $imagesPaths = [];
            if ($request->hasFile('land_images')) {
                foreach ($request->file('land_images') as $image) {
                    $imagesPaths[] = $image->store('land-images/' . $user->id, 'public');
                }
            }

            // Build documents JSON with titles and file paths
            $documentsPayload = [];
            $landDocuments = $request->input('land_documents', []);
            $documentFiles = $request->file('land_document_files', []);
            foreach ($landDocuments as $index => $doc) {
                $title = $doc['title'] ?? '';
                $filePath = null;
                if (isset($documentFiles[$index])) {
                    $filePath = $documentFiles[$index]->store('land-documents/' . $user->id, 'public');
                }
                if ($title !== '' || $filePath) {
                    $documentsPayload[] = ['title' => $title, 'path' => $filePath];
                }
            }

            $landId = DB::table('lands')->insertGetId([
                'farmer_id'           => $user->id,
                'size'                => $request->size,
                'ownership_type'      => $request->ownership_type,
                'registration_number' => $request->registration_number,
                'latitude'            => $request->latitude,
                'longitude'           => $request->longitude,
                'notes'               => $request->notes,
                'land_images'         => empty($imagesPaths) ? null : json_encode($imagesPaths),
                'land_documents_paths_and_document_titles' => empty($documentsPayload) ? null : json_encode($documentsPayload),
                'status'              => 'pending',
                'created_at'          => now(),
                'updated_at'          => now(),
            ]);

            // Increment total_lands in farmer_verification_data
            DB::table('farmer_verification_data')
                ->where('user_id', $user->id)
                ->increment('total_lands');

            DB::commit();

            $land = DB::table('lands')->find($landId);

            return response()->json(['success' => true, 'land' => $land], 201);
        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to register land.',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    public function show(Request $request, int $id)
    {
        $user = $request->user();

        $land = DB::table('lands')
            ->where('id', $id)
            ->where('farmer_id', $user->id)
            ->first();

        if (!$land) {
            return response()->json(['success' => false, 'message' => 'Land not found.'], 404);
        }

        $land->land_images = json_decode($land->land_images ?? '[]', true) ?: [];
        $land->land_documents = json_decode($land->land_documents_paths_and_document_titles ?? '[]', true) ?: [];

        return response()->json(['success' => true, 'land' => $land], 200);
    }
}
