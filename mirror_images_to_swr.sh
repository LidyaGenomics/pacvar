#!/bin/bash
# Mirror PacVar pipeline images from quay.io to Huawei SWR.
# Uses crane for reliable registry-to-registry copy (no Docker daemon quirks).
#
# Prerequisites:
#   docker login swr.tr-west-1.myhuaweicloud.com -u <org>@<ak> -p <login_key>
#   (crane reads credentials from ~/.docker/config.json)
#
# Usage:
#   bash mirror_images_to_swr.sh

set -euo pipefail

SWR_REGISTRY="swr.tr-west-1.myhuaweicloud.com/lidyagenomics"

# Install crane if not present
if ! command -v crane &>/dev/null; then
    echo "Installing crane..."
    curl -sL "https://github.com/google/go-containerregistry/releases/latest/download/go-containerregistry_Linux_x86_64.tar.gz" | tar -xz -C /tmp crane
    CRANE="/tmp/crane"
else
    CRANE="crane"
fi

# All container images used by pacvar (13 total).
# Includes FASTQC and GUNZIP defensively even though they are not currently
# invoked — prevents pull failures if they are ever enabled.
IMAGES=(
    "quay.io/biocontainers/pbmm2:1.14.99--h9ee0642_0"
    "quay.io/biocontainers/samtools:1.21--h50ea8bc_0"
    "quay.io/nf-core/deepvariant:1.6.1"
    "quay.io/biocontainers/pbsv:2.9.0--h9ee0642_0"
    "quay.io/biocontainers/hiphase:1.4.5--h9ee0642_0"
    "quay.io/biocontainers/trgt:1.2.0--h9ee0642_0"
    "quay.io/biocontainers/lima:2.9.0--h9ee0642_1"
    "quay.io/biocontainers/bcftools:1.20--h8b25389_0"
    "quay.io/biocontainers/htslib:1.20--h5efdd21_2"
    "quay.io/biocontainers/gatk4:4.5.0.0--py36hdfd78af_0"
    "quay.io/biocontainers/multiqc:1.27--pyhdfd78af_0"
    "quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0"
    "quay.io/nf-core/ubuntu:22.04"
)

for SOURCE in "${IMAGES[@]}"; do
    # Extract image name and tag from full source path
    # e.g., "quay.io/biocontainers/pbmm2:1.14.99--h9ee0642_0" -> "pbmm2" and "1.14.99--h9ee0642_0"
    IMAGE_WITH_TAG="${SOURCE##*/}"     # pbmm2:1.14.99--h9ee0642_0
    IMAGE_NAME="${IMAGE_WITH_TAG%%:*}" # pbmm2
    TAG="${IMAGE_WITH_TAG#*:}"         # 1.14.99--h9ee0642_0

    TARGET="${SWR_REGISTRY}/${IMAGE_NAME}:${TAG}"

    echo "============================================"
    echo "Mirroring: ${SOURCE}"
    echo "       To: ${TARGET}"
    echo "============================================"

    "${CRANE}" copy --platform linux/amd64 "${SOURCE}" "${TARGET}"

    # Verify the image was pushed successfully
    if "${CRANE}" manifest "${TARGET}" > /dev/null 2>&1; then
        echo "Verified: ${IMAGE_NAME}:${TAG}"
    else
        echo "WARNING: Verification failed for ${IMAGE_NAME}:${TAG}"
    fi

    echo ""
done

echo "All images mirrored successfully!"
