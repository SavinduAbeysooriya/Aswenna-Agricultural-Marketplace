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
            $land->land_images = json_decode($land->land_images ?? '[]', true) ?: [];
            $land->land_documents = json_decode($land->land_documents_paths_and_document_titles ?? '[]', true) ?: [];

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

    public function update(Request $request, int $id)
    {
        $user = $request->user();

        $land = DB::table('lands')
            ->where('id', $id)
            ->where('farmer_id', $user->id)
            ->first();

        if (!$land) {
            return response()->json(['success' => false, 'message' => 'Land not found.'], 404);
        }

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
            $existingImages = json_decode($land->land_images ?? '[]', true) ?: [];
            $existingDocs = json_decode($land->land_documents_paths_and_document_titles ?? '[]', true) ?: [];

            // Allow client to drop existing files by sending keep lists.
            $keepImages = $request->input('keep_land_images');
            if (is_array($keepImages)) {
                $existingImages = array_values(array_intersect($existingImages, $keepImages));
            }

            $keepDocs = $request->input('keep_land_documents');
            if (is_array($keepDocs)) {
                $existingDocsByPath = [];
                foreach ($existingDocs as $doc) {
                    $path = is_array($doc) ? ($doc['path'] ?? null) : null;
                    if ($path) $existingDocsByPath[$path] = $doc;
                }

                $filteredDocs = [];
                foreach ($keepDocs as $doc) {
                    $path = is_array($doc) ? ($doc['path'] ?? null) : null;
                    if (!$path) continue;
                    if (!isset($existingDocsByPath[$path])) continue;
                    $title = is_array($doc) ? ($doc['title'] ?? '') : '';
                    $filteredDocs[] = ['title' => $title, 'path' => $path];
                }
                $existingDocs = $filteredDocs;
            }

            $newImages = [];
            if ($request->hasFile('land_images')) {
                foreach ($request->file('land_images') as $image) {
                    $newImages[] = $image->store('land-images/' . $user->id, 'public');
                }
            }

            $documentsPayload = $existingDocs;
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

            DB::table('lands')
                ->where('id', $id)
                ->update([
                    'size'                => $request->size,
                    'ownership_type'      => $request->ownership_type,
                    'registration_number' => $request->registration_number,
                    'latitude'            => $request->latitude,
                    'longitude'           => $request->longitude,
                    'notes'               => $request->notes,
                    'land_images'         => empty(array_merge($existingImages, $newImages))
                        ? null
                        : json_encode(array_values(array_merge($existingImages, $newImages))),
                    'land_documents_paths_and_document_titles' => empty($documentsPayload) ? null : json_encode($documentsPayload),
                    // Always re-queue verification when farmer updates land details
                    'status'              => 'pending',
                    'updated_at'          => now(),
                ]);

            DB::commit();

            $updatedLand = DB::table('lands')->find($id);
            $updatedLand->land_images = json_decode($updatedLand->land_images ?? '[]', true) ?: [];
            $updatedLand->land_documents = json_decode($updatedLand->land_documents_paths_and_document_titles ?? '[]', true) ?: [];

            return response()->json([
                'success' => true,
                'message' => 'Land updated. Status set to pending for approval.',
                'land' => $updatedLand,
            ], 200);
        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to update land.',
                'error'   => $e->getMessage(),
            ], 500);
        }
    }
}
