#!/usr/bin/env bash
# Türkçe dublaj eklentisini, TEMİZ bir Nuvio (upstream) çalışma klasörüne uygular.
#   kullanım:  dub-addon/apply.sh <upstream-klasörü>
# Ortam değişkenleri (hepsi isteğe bağlı):
#   DUB_RELEASE_OWNER / DUB_RELEASE_REPO : uygulama içi güncelleyicinin bakacağı depo
#   DUB_REV                              : bu upstream sürümü için eklenti sürüm sayacı (1,2,3…)
#   DUB_FORK_MODE=1                      : Nuvio-One forku üstüne uygula. Güncelleyici deposu ve sürüm
#                                          numarasına DOKUNMAZ (fork bunları kendi yönetir).
#   DUB_FORK_TAG                         : (fork modunda zorunlu) fork sürüm etiketi, ör. 1.2.0-beta.1.3
set -euo pipefail

ADDON="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:?kullanım: apply.sh <upstream-klasörü>}"
cd "$TARGET"

OWNER="${DUB_RELEASE_OWNER:-claaude8}"
REPO="${DUB_RELEASE_REPO:-Nuvio-One-Dub}"
REV="${DUB_REV:-1}"

[ -f app/build.gradle.kts ] || { echo "::error::'$PWD' içinde app/build.gradle.kts yok: bu klasör Nuvio-One uygulama kodu değil (fork kodu çekilmemiş)."; exit 6; }

# --- 1) Yeni dosyalar (overlay): upstream'de aynı yolda dosya varsa dur -------------
while IFS= read -r -d '' f; do
  rel="${f#"$ADDON/overlay/"}"
  if git ls-files --error-unmatch "$rel" >/dev/null 2>&1; then
    echo "::error::OVERLAY ÇAKIŞMASI: upstream artık '$rel' dosyasını içeriyor. Eklentideki kopya yerine upstream'inkiyle birleştirilmeli (bkz. dub-addon/README.md)."
    exit 3
  fi
  mkdir -p "$(dirname "$rel")"
  cp "$f" "$rel"
done < <(find "$ADDON/overlay" -type f -print0)
echo "overlay: $(find "$ADDON/overlay" -type f | wc -l) yeni dosya eklendi"

# --- 2) Mevcut dosyalardaki küçük KANCALAR + sınıf sonuna eklenen üyeler ---------------
#     (satır numarasına bağlı değil; her kanca fonksiyon/sınıf adıyla kapsamlanır, bkz. scripts/apply-hooks.py)
if ! python3 -I "$ADDON/scripts/apply-hooks.py" "$ADDON"; then
  echo "::error::Eklenti kancaları güncel Nuvio koduyla birleşemedi. Elle çözüm gerekli (bkz. dub-addon/README.md)."
  exit 2
fi

if [ "${DUB_FORK_MODE:-0}" = "1" ]; then
  # Güncelleyici deposu iş akışta -PlivetvUpdateRepo ile verilir. Sürüm adı ve numarası ise
  # fork'un sürümünden türetilir ve iş akışına yazdırılır (VERSION_NAME / BUILD_NUMBER).
  #   fork 1.2.0-beta.1.3  ->  1.2.0-beta.1.3.dub.1   (uygulamadaki güncelleyici bunu fork'un
  #   kendi 1.2.0-beta.1.3 sürümünden yeni sayar; fork beta.1.4 çıkarınca 1.2.0-beta.1.4.dub.1 olur)
  # versionCode = fork kodu x 100 + BUILD_NUMBER. Fork'un kendi derlemeleri 1..49 kullanır diye
  # eklenti 50'den başlar, böylece aynı sürümde eklentili APK her zaman daha yüksek koddur.
  FORK_TAG="${DUB_FORK_TAG:?DUB_FORK_TAG gerekli (fork sürümü)}"
  if [ "$REV" -gt 49 ]; then
    echo "::error::Aynı fork sürümünde en fazla 49 eklenti derlemesi yapılabilir (REV=$REV)"
    exit 7
  fi
  echo "VERSION_NAME=${FORK_TAG}.dub.${REV}"
  echo "BUILD_NUMBER=$((50 + REV))"
  echo "fork modu: güncelleyici deposu ve sürüm adı/numarası iş akışından geliyor"
  exit 0
fi

# --- 3) Güncelleyiciyi bu forka yönlendir + sürüm numarası ----------------------------
GRADLE=app/build.gradle.kts
base_name="$(sed -nE 's/^[[:space:]]*versionName = "([^"]+)".*/\1/p' "$GRADLE" | head -1)"
base_code="$(sed -nE 's/^[[:space:]]*versionCode = ([0-9]+).*/\1/p' "$GRADLE" | head -1)"
[ -n "$base_name" ] && [ -n "$base_code" ] || { echo "::error::versionName/versionCode bulunamadı"; exit 4; }

case "$base_name" in
  *-*) new_name="${base_name}.dub.${REV}" ;;   # 1.1.0-beta.9  -> 1.1.0-beta.9.dub.1
  *)   new_name="${base_name}-dub.${REV}"  ;;   # 1.1.0         -> 1.1.0-dub.1
esac
new_code=$(( base_code * 1000 + (REV % 1000) ))

# Güncelleyicinin bakacağı depo (BuildConfig.GITHUB_OWNER / GITHUB_REPO)
sed -i "/\"GITHUB_OWNER\"/ s/NuvioMedia/${OWNER}/" "$GRADLE"
sed -i "/\"GITHUB_REPO\"/ s/NuvioTV/${REPO}/" "$GRADLE"
sed -i -E "s|^([[:space:]]*versionName = )\"[^\"]+\"|\1\"${new_name}\"|" "$GRADLE"
sed -i -E "s|^([[:space:]]*versionCode = )[0-9]+|\1${new_code}|" "$GRADLE"

grep "GITHUB_OWNER" "$GRADLE" | grep -q "${OWNER}" \
  && grep "GITHUB_REPO" "$GRADLE" | grep -q "${REPO}" \
  && grep -q "versionName = \"${new_name}\"" "$GRADLE" \
  || { echo "::error::build.gradle.kts düzenlemesi doğrulanamadı"; exit 5; }

echo "VERSION_NAME=${new_name}"
echo "VERSION_CODE=${new_code}"
echo "UPSTREAM_VERSION=${base_name}"
