<?php
declare(strict_types=1);

/**
 * Partial UPDATE for listing photos img1–img4.
 * POST delete_img1=1 … delete_img4=1 clears a slot; uploaded file replaces it.
 */
function crg_append_listing_photo_updates(array &$sets, array &$params, string &$types): void
{
    for ($i = 1; $i <= 4; $i++) {
        $key = 'img' . $i;
        if (!empty($_POST['delete_' . $key])) {
            $sets[] = "{$key} = NULL";
            continue;
        }
        if (!empty($_FILES[$key]['tmp_name']) && is_uploaded_file($_FILES[$key]['tmp_name'])) {
            $sets[] = "{$key} = ?";
            $params[] = file_get_contents($_FILES[$key]['tmp_name']);
            $types .= 's';
        }
    }
}

/**
 * Partial UPDATE for performer listing + document photos.
 * Multipart: img1–img4, imgDoc1–imgDoc4; DB columns imgdoc1–imgdoc4.
 */
function crg_append_performer_photo_updates(array &$sets, array &$params, string &$types): void
{
    crg_append_listing_photo_updates($sets, $params, $types);

    for ($i = 1; $i <= 4; $i++) {
        $fileKey = 'imgDoc' . $i;
        $dbCol = 'imgdoc' . $i;
        if (!empty($_POST['delete_' . $fileKey])) {
            $sets[] = "{$dbCol} = NULL";
            continue;
        }
        if (!empty($_FILES[$fileKey]['tmp_name']) && is_uploaded_file($_FILES[$fileKey]['tmp_name'])) {
            $sets[] = "{$dbCol} = ?";
            $params[] = file_get_contents($_FILES[$fileKey]['tmp_name']);
            $types .= 's';
        }
    }
}
