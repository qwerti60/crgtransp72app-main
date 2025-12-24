#!/bin/bash

ORIGINAL_ICON="icon.png"               # Исходная иконка
BASE_DIR="./src/main/res/"             # Базовая папка ресурсов Android

# Размеры иконок для каждой плотности
ICON_SIZES=(24 36 48 72 96)           # Размеры для MDPI, HDPI, XHDPI, XXHDPI, XXXHDPI соответственно
DENSITY_NAMES=(mdpi hdpi xhdpi xxhdpi xxxhdpi)

for i in "${!ICON_SIZES[@]}"; do
  SIZE=${ICON_SIZES[$i]}
  DENSITY=${DENSITY_NAMES[$i]}

  RESOURCE_PATH="${BASE_DIR}/drawable-${DENSITY}"
  mkdir -p "$RESOURCE_PATH"           # Создаем директорию, если её нет

  magick "$ORIGINAL_ICON" -resize "${SIZE}x${SIZE}" "$RESOURCE_PATH/icon.png"
done