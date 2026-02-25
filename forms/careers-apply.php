<?php
declare(strict_types=1);

require_once __DIR__ . '/careers-lib.php';

careers_ensure_storage();

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST') {
  careers_respond(405, ['message' => 'Method not allowed.']);
}

try {
  $name = trim((string) ($_POST['applicant_name'] ?? ''));
  $email = trim((string) ($_POST['applicant_email'] ?? ''));
  $phone = trim((string) ($_POST['applicant_phone'] ?? ''));
  $jobTitle = trim((string) ($_POST['job_title'] ?? ''));
  $jobId = trim((string) ($_POST['job_id'] ?? ''));
  $message = trim((string) ($_POST['cover_message'] ?? ''));

  if ($name === '' || $email === '' || $phone === '') {
    careers_respond(422, ['message' => 'Name, email, and phone are required.']);
  }
  if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    careers_respond(422, ['message' => 'Please provide a valid email address.']);
  }
  if (!isset($_FILES['resume_file'])) {
    careers_respond(422, ['message' => 'Resume file is required.']);
  }

  $resumeFileName = careers_store_upload(
    $_FILES['resume_file'],
    ['pdf', 'doc', 'docx'],
    CAREERS_RESUMES_UPLOAD_DIR,
    'resume'
  );

  $applications = careers_load_applications();
  $applications[] = [
    'id' => 'app-' . date('YmdHis') . '-' . bin2hex(random_bytes(3)),
    'submitted_at' => date('c'),
    'name' => $name,
    'email' => $email,
    'phone' => $phone,
    'job_title' => $jobTitle,
    'job_id' => $jobId,
    'message' => $message,
    'resume_path' => 'forms/uploads/resumes/' . $resumeFileName
  ];

  careers_save_applications($applications);
  careers_respond(200, ['message' => 'Resume submitted successfully.']);
} catch (Throwable $error) {
  careers_respond(500, ['message' => $error->getMessage()]);
}

