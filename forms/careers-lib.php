<?php
declare(strict_types=1);

require_once __DIR__ . '/careers-config.php';

function careers_respond(int $status, array $payload): void {
  http_response_code($status);
  header('Content-Type: application/json; charset=utf-8');
  echo json_encode($payload, JSON_UNESCAPED_SLASHES);
  exit;
}

function careers_ensure_storage(): void {
  $directories = [
    dirname(CAREERS_DATA_FILE),
    CAREERS_JOBS_UPLOAD_DIR,
    CAREERS_RESUMES_UPLOAD_DIR
  ];

  foreach ($directories as $dir) {
    if (!is_dir($dir)) {
      mkdir($dir, 0775, true);
    }
  }

  if (!file_exists(CAREERS_DATA_FILE)) {
    file_put_contents(CAREERS_DATA_FILE, json_encode([], JSON_PRETTY_PRINT));
  }
  if (!file_exists(CAREERS_APPLICATIONS_FILE)) {
    file_put_contents(CAREERS_APPLICATIONS_FILE, json_encode([], JSON_PRETTY_PRINT));
  }
}

function careers_load_json_array(string $filePath): array {
  if (!file_exists($filePath)) {
    return [];
  }

  $raw = file_get_contents($filePath);
  if ($raw === false || trim($raw) === '') {
    return [];
  }

  $decoded = json_decode($raw, true);
  return is_array($decoded) ? $decoded : [];
}

function careers_save_json_array(string $filePath, array $records): void {
  file_put_contents($filePath, json_encode(array_values($records), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
}

function careers_load_jobs(): array {
  return careers_load_json_array(CAREERS_DATA_FILE);
}

function careers_save_jobs(array $jobs): void {
  careers_save_json_array(CAREERS_DATA_FILE, $jobs);
}

function careers_load_applications(): array {
  return careers_load_json_array(CAREERS_APPLICATIONS_FILE);
}

function careers_save_applications(array $applications): void {
  careers_save_json_array(CAREERS_APPLICATIONS_FILE, $applications);
}

function careers_is_admin_authorized(): bool {
  $headerKey = $_SERVER['HTTP_X_ADMIN_KEY'] ?? '';
  $postKey = $_POST['admin_key'] ?? '';
  $provided = trim((string) ($headerKey !== '' ? $headerKey : $postKey));
  return hash_equals(careers_admin_key(), $provided);
}

function careers_bool_value(mixed $value): bool {
  if (is_bool($value)) {
    return $value;
  }
  $asString = strtolower(trim((string) $value));
  return in_array($asString, ['1', 'true', 'yes', 'on'], true);
}

function careers_find_job_index(array $jobs, string $id): int {
  foreach ($jobs as $index => $job) {
    if ((string) ($job['id'] ?? '') === $id) {
      return (int) $index;
    }
  }
  return -1;
}

function careers_store_upload(array $file, array $allowedExtensions, string $targetDir, string $prefix): string {
  if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
    throw new RuntimeException('File upload failed.');
  }

  $size = (int) ($file['size'] ?? 0);
  if ($size <= 0 || $size > CAREERS_MAX_UPLOAD_BYTES) {
    throw new RuntimeException('Uploaded file exceeds allowed size.');
  }

  $original = (string) ($file['name'] ?? '');
  $extension = strtolower(pathinfo($original, PATHINFO_EXTENSION));
  if (!in_array($extension, $allowedExtensions, true)) {
    throw new RuntimeException('Invalid file type.');
  }

  $safeBase = preg_replace('/[^a-zA-Z0-9_-]+/', '-', pathinfo($original, PATHINFO_FILENAME));
  $safeBase = trim((string) $safeBase, '-');
  if ($safeBase === '') {
    $safeBase = 'file';
  }

  $targetName = $prefix . '-' . date('YmdHis') . '-' . $safeBase . '.' . $extension;
  $targetPath = rtrim($targetDir, '/\\') . DIRECTORY_SEPARATOR . $targetName;

  if (!move_uploaded_file((string) $file['tmp_name'], $targetPath)) {
    throw new RuntimeException('Unable to store uploaded file.');
  }

  return $targetName;
}

function careers_public_job(array $job): array {
  return [
    'id' => (string) ($job['id'] ?? ''),
    'title' => (string) ($job['title'] ?? ''),
    'department' => (string) ($job['department'] ?? ''),
    'location' => (string) ($job['location'] ?? ''),
    'employment_type' => (string) ($job['employment_type'] ?? ''),
    'summary' => (string) ($job['summary'] ?? ''),
    'description' => (string) ($job['description'] ?? ''),
    'pdf_url' => (string) ($job['pdf_url'] ?? ''),
    'posted_on' => (string) ($job['posted_on'] ?? ''),
    'is_active' => careers_bool_value($job['is_active'] ?? true)
  ];
}

