<?php
declare(strict_types=1);

require_once __DIR__ . '/careers-lib.php';

careers_ensure_storage();

if (!careers_is_admin_authorized()) {
  careers_respond(401, ['message' => 'Unauthorized. Provide a valid admin key.']);
}

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$jobs = careers_load_jobs();

if ($method === 'GET') {
  careers_respond(200, [
    'jobs' => array_map('careers_public_job', $jobs)
  ]);
}

if ($method !== 'POST') {
  careers_respond(405, ['message' => 'Method not allowed.']);
}

$action = strtolower(trim((string) ($_POST['action'] ?? '')));

try {
  if ($action === 'add') {
    $title = trim((string) ($_POST['title'] ?? ''));
    if ($title === '') {
      careers_respond(422, ['message' => 'Title is required.']);
    }

    $newJob = [
      'id' => 'job-' . date('YmdHis') . '-' . bin2hex(random_bytes(3)),
      'title' => $title,
      'department' => trim((string) ($_POST['department'] ?? '')),
      'location' => trim((string) ($_POST['location'] ?? '')),
      'employment_type' => trim((string) ($_POST['employment_type'] ?? 'Full-Time')),
      'summary' => trim((string) ($_POST['summary'] ?? '')),
      'description' => trim((string) ($_POST['description'] ?? '')),
      'posted_on' => date('Y-m-d'),
      'is_active' => careers_bool_value($_POST['is_active'] ?? '1'),
      'pdf_url' => trim((string) ($_POST['pdf_url'] ?? ''))
    ];

    if (isset($_FILES['job_pdf']) && (int) ($_FILES['job_pdf']['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_NO_FILE) {
      $fileName = careers_store_upload(
        $_FILES['job_pdf'],
        ['pdf'],
        CAREERS_JOBS_UPLOAD_DIR,
        'job-description'
      );
      $newJob['pdf_url'] = 'forms/uploads/jobs/' . $fileName;
    }

    $jobs[] = $newJob;
    careers_save_jobs($jobs);
    careers_respond(200, ['message' => 'Job posting added.', 'job' => careers_public_job($newJob)]);
  }

  if ($action === 'edit') {
    $id = trim((string) ($_POST['id'] ?? ''));
    if ($id === '') {
      careers_respond(422, ['message' => 'Job id is required for edit.']);
    }

    $index = careers_find_job_index($jobs, $id);
    if ($index < 0) {
      careers_respond(404, ['message' => 'Job not found.']);
    }

    $editableFields = ['title', 'department', 'location', 'employment_type', 'summary', 'description', 'pdf_url'];
    foreach ($editableFields as $field) {
      if (array_key_exists($field, $_POST)) {
        $jobs[$index][$field] = trim((string) $_POST[$field]);
      }
    }

    if (array_key_exists('is_active', $_POST)) {
      $jobs[$index]['is_active'] = careers_bool_value($_POST['is_active']);
    }

    if (isset($_FILES['job_pdf']) && (int) ($_FILES['job_pdf']['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_NO_FILE) {
      $fileName = careers_store_upload(
        $_FILES['job_pdf'],
        ['pdf'],
        CAREERS_JOBS_UPLOAD_DIR,
        'job-description'
      );
      $jobs[$index]['pdf_url'] = 'forms/uploads/jobs/' . $fileName;
    }

    careers_save_jobs($jobs);
    careers_respond(200, ['message' => 'Job posting updated.', 'job' => careers_public_job($jobs[$index])]);
  }

  if ($action === 'delete') {
    $id = trim((string) ($_POST['id'] ?? ''));
    if ($id === '') {
      careers_respond(422, ['message' => 'Job id is required for delete.']);
    }

    $index = careers_find_job_index($jobs, $id);
    if ($index < 0) {
      careers_respond(404, ['message' => 'Job not found.']);
    }

    array_splice($jobs, $index, 1);
    careers_save_jobs($jobs);
    careers_respond(200, ['message' => 'Job posting deleted.']);
  }

  careers_respond(422, ['message' => 'Unknown action. Use add, edit, or delete.']);
} catch (Throwable $error) {
  careers_respond(500, ['message' => $error->getMessage()]);
}

