# dub-addon — Türkçe dublaj + senkron eklentisi (Nuvio-One)

> Bu depo Nuvio-One'ın kopyası değildir: iş akışı [zoga2o3-ops/Nuvio-One](https://github.com/zoga2o3-ops/Nuvio-One)'un **son yayınlanan sürümünü** kendisi çeker. Depo **public** olmalı (APK uygulama içinden indirilir).

Nuvio-One'ın kaynak koduna **elle dosya kopyalamadan**, otomatik uygulanan eklenti paketi.
Nuvio-One yeni sürüm yayınlayınca GitHub Actions yeni kodu alır, eklentiyi üstüne uygular, APK derler ve bu depoda
**Release** olarak yayınlar. Uygulamadaki *Güncelleme* ekranı bu release'e bakar.

```
Nuvio-One (zoga2o3-ops/Nuvio-One) ──► [her gün 03:17 UTC] ──► son sürüm + dub-addon uygula ──► imzalı APK
                                                                                                  │
                                                    uygulama içi güncelleme  ◄── Release (bu depo)

dublaj kaynak listesi:  claaude8/dupiii  ──►  dublaj_kaynaklari.json  (uygulama çalışırken çeker, APK gerekmez)
```

## Klasörler
| Yol | İçerik |
|---|---|
| `overlay/` | Tamamen **yeni** dosyalar (`core/dub/*`, `DubAudioRows`, `StreamSidecarAudio`, `PlayerRuntimeControllerDub*`, `DubExternalAudios` …). Dublaj mantığının neredeyse tamamı burada; upstream'de olmadığı için çakışmaz. |
| `append/` | Upstream sınıflarının **sonuna eklenen** üyeler (`PlayerRuntimeController`, `PlayerMediaSourceFactory`). Dosyanın son `}` karakteri değişmediği sürece çakışmaz. |
| `scripts/apply-hooks.py` | Upstream dosyalarına dokunan birkaç **tek satırlık kanca** + sınıf sonuna ekleme. Her kanca fonksiyon/sınıf adıyla kapsamlanır, satır numarasına bağlı değildir. |
| `apply.sh` | overlay + kancalar + (fork modunda) sürüm adı/numarası üretimi |
| `scripts/make-keystore.sh` | Sabit imza anahtarı üretir (yalnızca kendi anahtarını kullanmak istersen) |
| `UPSTREAM_BASE` | Eklentinin ilk uyarlandığı Nuvio-One commit'i (bilgi amaçlı) |

`.github/workflows/fork-sync-release.yml` hepsini çalıştıran iş akışıdır.

> Eski yapıdaki `patches/*.patch` (15 yama) ve `export-patches.sh` kaldırıldı. `Stream`, `LocalScraperResult`, `StreamRepositoryImpl`,
> `PlayerScreen`, `PlayerUiState`, `StreamScreenViewModel` gibi dosyalara artık dokunulmuyor.

## Bir kere yapılacak kurulum
1. **İmza:** Ek bir şey yapman gerekmez. Varsayılan olarak Nuvio-One'ın kendi anahtarı (`keystore/livetv-fork.jks`) kullanılır;
   böylece mevcut Nuvio-One kurulumları bu sürümle güncellenebilir. Kendi anahtarını kullanmak istersen
   `dub-addon/scripts/make-keystore.sh` çalıştırıp çıkan değeri `LIVETV_KEYSTORE_BASE64` **Secret**'ı olarak ekle ve `.jks`'i yedekle.
   Her derlemede **aynı** anahtar kullanılmalı; yoksa Android güncellemeyi reddeder.
2. **API anahtarları (isteğe bağlı):** `NUVIO_BACKEND_URL`, `NUVIO_BACKEND_KEY`, `TMDB_API_KEY`, `TRAKT_CLIENT_ID`, `TRAKT_CLIENT_SECRET`,
   `SIMKL_CLIENT_ID`, `SIMKL_APP_NAME`, `MDBLIST_CLIENT_ID` vb. Secret olarak eklenebilir; yoksa iş akışı varsayılanları kullanır.
   Anahtarları **depoya commit'leme**, sadece Secret olarak sakla.
3. **Actions'ı aç:** Zamanlanmış iş akışları yeni depolarda kapalı gelebilir. *Actions* sekmesinden etkinleştir.
4. **İlk sürümü başlat:** Actions → *Fork senkron + dublaj eklentili release* → **Run workflow**. Bittiğinde Release'te APK görünür.
   İstersen `fork_ref` alanına belirli bir Nuvio-One etiketi yazabilirsin; boş bırakırsan son yayınlanan sürüm kullanılır.
5. **Telefona/TV'ye bir kez elle kur.** İmza anahtarı farklıysa önce eski sürümü kaldırman gerekebilir. Bundan sonrası uygulama içinden güncellenir.

## Otomatik arama ve otomatik senkron anahtarları
Oynatıcıda **Ses** menüsünde iki satırın sağında birer anahtar (Açık/Kapalı) vardır:

| Satır | Satıra basınca | Anahtar |
|---|---|---|
| Türkçe dublaj ara | Dublajı hemen arar | Video açılınca dublajın kendiliğinden aranması (varsayılan **Açık**) |
| Dublajı otomatik senkronla | Seçili dublajı hemen ölçer | Dublaj eklenince senkronun kendiliğinden ölçülmesi (varsayılan **Kapalı**) |

Seçim cihazda saklanır (`nuvio_dub` / `auto_search_enabled`, `auto_sync_enabled`) ve sen değiştirene kadar
videolar, uygulamanın yeniden başlatılması ve güncellemeler arasında aynı kalır. Kumandada: satırda **Tamam** işlemi
çalıştırır, **Sağ** tuşu anahtara geçer, anahtarda **Tamam** açıp kapatır. Anahtar yalnızca sonraki videoları etkiler.
Uzak listedeki `autoSearch: false` ayarı hâlâ geçerlidir; otomatik aramanın çalışması için ikisi de açık olmalı.

## Altyazı gecikmesi = ses gecikmesi
Dublaj senkronu uygulandığında (elle ölçüm, otomatik ölçüm, **kayıtlı sonuç** ya da tarifteki sabit gecikme) altyazı gecikmesi de
ses gecikmesiyle **aynı değere** (aynı sayı, aynı işaret) çekilir: ses -2300 ms ise altyazı da -2300 ms olur. Video kapatılıp açılınca
kayıtlı senkron yeniden devreye girdiğinde altyazı da yeniden aynı değere gelir. Orijinal sese dönersen altyazının önceki gecikmesi geri gelir (arada elle değiştirdiysen dokunulmaz), dublaja dönünce yeniden eşitlenir.
Altyazı değeri ayrıca saklanmaz; sonraki oturumda
dublajın kayıtlı gecikmesinden yeniden hesaplanır. Sonradan altyazıyı elle değiştirirsen o değer geçerli kalır, bir sonraki senkrona kadar.
Kod: `mirrorAudioDelayToSubtitle()` (`PlayerRuntimeControllerDubSync.kt`). Dublajın dilindeki gömülü altyazılar zaten dublaj
kaymasını Nuvio'nun kendi mantığıyla alır; çift sayılmasın diye o kısım düşülür. Kapatmak için `applyMeasuredDubDelay` ve
`applyDubAudioDelay` içindeki `mirrorAudioDelayToSubtitle()` çağrılarını silmek yeter.

## Senkron karar sırası: önce ses, altyazı yalnızca yedek
Ölçüm bir **kademe**dir; iki yöntem oy birliğiyle değil, sırayla denenir (`DubSyncAnalyzer.analyze`):

1. **Ses (müzik/efekt)** — kesin sonuç verirse hemen uygulanır ve **altyazıya hiç bakılmaz**. Ses sonucu ile altyazı sonucu
   birbirinden çok farklı olsa bile (eskiden "yöntemler birbiriyle çelişiyor" diye çöpe atılırdı) artık **ses kazanır**.
2. Ses kesin değilse, pencere başına tepe noktalarına doğru uydurulur (sabit doğru → sonuç, eğimli doğru → hız farkı/*Drift*).
3. **Gömülü altyazı** — yalnızca ses 1. ve 2. adımda sonuç vermediyse devreye girer. Aynı pencereler kullanılır (altyazı
   cue'ları pencereyle birlikte zaten okunmuştu), yeniden indirme yoktur. Sonuç yaklaşık (±150 ms) sayılır; ses kısmen
   okunuyorsa ve altyazı değerinin ±300 ms çevresinde net bir tepe gösteriyorsa `gömülü altyazı + müzik/efekt` olarak inceltilir.
4. Altyazıda da sabit/eğimli doğru aranır; hiçbiri yoksa "elle ayarlayın".

**Denetleyici döngüsü** (`PlayerRuntimeControllerDubSync.kt`): pencereler okunurken her turda yalnızca ses analiz edilir
(`subtitleFallback = false`). Tüm pencereler bitip ses sonuç vermediyse aynı pencerelerle altyazı denenir. Ses bulunur bulunmaz
döngü durur; eski "altyazı sonucunu inceltmek için ek pencere" (`canRefine`) kaldırıldı.

**TrueHD/DTS-HD gibi çözülemeyen orijinal ses:** ilk 2 pencerede hiçbir pencerede orijinal ses çözülemediyse ve videoda
gömülü altyazı varsa ses aşaması atlanır (`skipAudio`), doğrudan altyazıyla ölçülür (Logcat `DubSync`:
`skipping the audio stage`). Gömülü altyazı da yoksa ölçüm güvenilmez der.

**Toast** hangi kademenin çalıştığını gösterir: `[müzik/efekt, 24 sn]`, `[gömülü altyazı – ses yetersizdi, 31 sn]`,
`[gömülü altyazı + müzik/efekt, 31 sn]`.

**Bilinen bedel:** ses kesin sonuç vermezse altyazıya geçmeden önce tüm pencereler (en çok 8) okunur; eskiden altyazı
3. pencerede sonuç verirse ölçüm orada biterdi. Ses tek başına karar verdiği için eşikler (`minPsr`, destek oranı) eskisi
gibi sıkı tutuldu; altyazı artık yanlış bir ses tepesini yakalayan ikinci bir kontrol değildir.

**Birim test:** `overlay/app/src/test/java/com/nuvio/tv/core/dub/DubSyncAnalyzerTest.kt` (JVM, JUnit4, sentetik ve deterministik
pencereler). Senaryolar: ses kesin + altyazı çelişiyor → ses kazanır; ikisi uyuşuyor; orijinal ses çözülemiyor → altyazı;
ses yetersiz → altyazı yalnızca yedek (`subtitleFallback = false` iken sonuç yok); hiçbir şey okunamıyor → güvenilmez.
Çalıştırmak için Nuvio klasöründe `./gradlew :app:testFullDebugUnitTest --tests "*DubSyncAnalyzerTest"` (görev adı
flavor'a göre değişebilir).

## Senkron arama aralığı
Otomatik ölçüm dublajın orijinalden **±15 saniyeye kadar** kaymış olmasını yakalar (eskiden ±8 sn). Bunun için her
pencerede dublaj sesi, orijinalden 15 sn önce başlayıp 15 sn sonra biten, toplam 45 sn'lik bir parça olarak okunur;
orijinal taraf (ağır olan) 15 sn'lik pencere olarak kalır. Dublaj küçük bir ses dosyası olduğundan ek maliyet azdır.
Kayma sabit değilse (25 ↔ 23.976 fps gibi hız farkı) ölçüm yine güvenilir değil der.

## Hız farkı (kayma sabit değilse)
Dublaj videodan farklı hızdaysa (ör. 25 fps PAL kaynaklı dublaj, 23.976 fps video: dublaj %4,1 kısa) kayma film boyunca
büyür ve tek bir gecikmeyle düzelmez. Eklenti bunu iki yolla ayırt eder:
- **Küçük hız farkı** (24 ↔ 23.976 gibi, yaklaşık %0,1): her pencerenin kendi kayması bulunup konuma göre bir doğru
  uydurulur. Doğru eğimliyse "Kayma sabit değil" denir ve gecikme **şu anki konuma göre** ayarlanır (yalnızca menüden elle
  çalıştırınca; otomatik modda dokunulmaz). İlerledikçe yeniden senkronlamak gerekir. Doğru düzse (diğer pencereler
  gürültüymüş), normal sonuç olarak uygulanır.
- **Büyük hız farkı** (PAL %4,1 gibi): kayma ±15 sn aralığının çok dışına çıkar, ölçüm başarısız olur. Bu durumda dublajın ve
  videonun süreleri ayrıca okunur. Fark **bilinen bir hız değişimiyle** (23.976 ↔ 25 ya da 24 ↔ 25 fps) örtüşüyorsa dublaj
  otomatik olarak yavaşlatılır (ya da hızlandırılır) ve geriye kalan sabit kayma yeniden ölçülür (aşağıya bakın).
  Örtüşmüyorsa (farklı kurgu, fazladan bölüm olabilir) hiçbir şey uygulanmaz; yalnızca fark mesajda gösterilir.

## Dublajı yavaşlatma / hızlandırma (zaman uzatma)
Yalnızca menüden elle çalıştırılan senkronda (otomatik mod tahmin üzerine bir şey değiştirmez) ve süre oranı bilinen bir hız
farkıyla örtüşünce devreye girer. Üç parça birlikte çalışır:
- `DubStretchMediaSource`: dublaj kaynağının zaman çizgisini film zamanına çevirir (dublaj zamanı = film zamanı × oran).
  Sarma (seek) doğru dublaj konumuna düşer, birleşik süre filmin süresi olur. Dublajın ses biçimini `DubStretchTag` ile işaretler.
- `DubStretchAudioSink`: işaretli sesi oranın tersiyle, perdeyi koruyarak (Media3 `SonicAudioProcessor`) uzatır. Gerçek ses
  çıkışına yalnızca film uzunluğunda ses girer; saat ve video bozulmaz. Başka hiçbir ses etkilenmez. Yalnızca 16-bit PCM
  uzatılır; AC-3/E-AC-3 dublaj bu durumda geçişle değil PCM'e çözülerek çalınır.
- `DubSpeed.knownRatio`: oranı yalnızca bilinen hız çiftlerinden birine uyuyorsa verir.

Oran video + dublaj çifti için cihazda hatırlanır (`dub_stretch_memory`); sonraki açılışta dublaj baştan uzatılmış gelir.
Uzatılmış dublajın ölçümünde dublaj penceresi kendi zamanında okunur ve film zaman ızgarasına yeniden örneklenir
(`DubStretch.toFilmTime`), böylece analiz kodu değişmeden çalışır.

Bağlantı noktaları: `createMediaSource` sarmalayıcısı (`mergeDubAudios`) ve `PlayerRuntimeControllerInitialization` içindeki tek satırlık ses çıkışı kancası. Upstream bunları değiştirirse `apply-hooks.py` net bir hatayla durur.

**Senkron süresi.** Hız farkı artık ilk pencerede anlaşılır: dublajın süresi (küçük bir başlık okuması, ilk pencereyle paralel)
ile ilk pencerenin zaten bildiği video süresi karşılaştırılır; bilinen bir oranla örtüşüyorsa kalan pencereler hiç okunmaz,
dublaj uzatılıp kalan kayma ölçülür. Ek video açılışı ya da ek indirme yoktur. Uzatmadan sonra ölçüm güvenilmezse uzatma
geri alınır. Sarmada `MergingMediaPeriod`'un istediği tam konum eşitliği `DubStretchMediaSource` içinde korunur.

Sorun giderme (Logcat `DubStretch`): `dub format tagged` satırı var ama `stretching dub` yoksa etiket ses çıkışına ulaşmıyor
(ör. FFmpeg çözücüsü); `foreign customData` satırı bunu gösterir.

Kapsam dışı: yalnızca ExoPlayer'da çalışır; oran elle girilemez; hatırlanan oran sonraki açılışlarda da uygulanır.

## Film süresine en yakın 2 dublaj
Bulunan dublajlardan yalnızca **film süresine en yakın ilk ikisi** oynatıcıya verilir; en yakın olan 1. sıradadır ve otomatik seçilir.
- Dublajın süresi, ses akışının (HLS) küçük oynatma listesindeki `#EXTINF` değerlerinin toplamından okunur (`DubHls.durationMs`); ayrı bir ses indirmesi ya da ek oynatıcı açılışı yoktur. Okunamayan (süresi bilinmeyen) kaynaklar süresi bilinenlerden sonra, dosyadaki sırayla gelir.
- Film süresi aramayı ya da sayfa eşleştirmeyi **etkilemez**; yalnızca bulunanları sıralamak için kullanılır (`DubRequest.filmDurationMs`). Süre bilinmiyorsa dosyadaki ilk iki kaynak kalır.
- Sayı `DubSourceManager.MAX_DUBS` sabitindedir. Süre farkı Logcat'te `DubSource` etiketiyle yazılır (`diff=…ms -> kept #1`).
- Not: 25 fps PAL hızındaki dublaj (film %4,1 uzun/kısa) süre olarak uzak görünür; daha yakın iki kaynak varsa elenir.

## Nasıl güncellenir?
- Her gün otomatik kontrol edilir. İş akışı Nuvio-One'ın **en son yayınlanan sürümüne** (Releases, taslaklar hariç) bakar.
  Nuvio-One yeni bir sürüm yayınlamadıysa ve `dub-addon/` değişmediyse derleme atlanır. Ara commit'ler yeni APK üretmez.
- Sürüm adı: Nuvio-One `1.2.0-beta.1.3` ise bu depo `1.2.0-beta.1.3.dub.1`, `.dub.2` … üretir. Nuvio-One `beta.1.4`'e geçince
  `1.2.0-beta.1.4.dub.1` çıkar ve uygulama içinde güncelleme bildirimi görünür. `versionCode` = fork kodu × 100 + (50 + sayaç).
- Güncelleyicinin baktığı depo `-PlivetvUpdateRepo` ile verilir; `apply.sh` fork modunda (`DUB_FORK_MODE=1`) `build.gradle.kts`'ye dokunmaz.
- Elle tetiklemek için *Run workflow* (isteğe bağlı *force*, *fork_ref*).
- GitHub, 60 gün hareketsiz public depolarda zamanlanmış iş akışlarını kapatır. İş akışı ayda bir `keepalive` dalına
  boş bir commit atarak bunu önlemeye çalışır (ana dal geçmişine karışmaz). Yine de Actions sekmesinde iş akışı
  "disabled" görünürse elle yeniden etkinleştir.

## Çakışma olursa
Nuvio-One, kancaların bağlandığı fonksiyonu/satırı değiştirirse iş akışı **durur, APK yayınlamaz** ve bir issue açar
(eski APK çalışmaya devam eder). Log'da hangi kancanın yerleşmediği açıkça yazar:
```
::error::kanca YERLEŞMEDİ  PlayerRuntimeControllerStreams  -> streamSubtitles = stream.subtitles: 0 eşleşme (1 bekleniyordu)
```
Düzeltmek için:
```bash
git clone https://github.com/zoga2o3-ops/Nuvio-One nuvio && cd nuvio
DUB_FORK_MODE=1 DUB_FORK_TAG=test /yol/bu-depo/dub-addon/apply.sh .   # hangi kanca tutmuyor gösterir
# scripts/apply-hooks.py içinde o kancanın (hook_*) desenini yeni koda göre güncelle
```
Kancalar tek satırlıktır; çoğu zaman yalnızca bir regex'i ya da eklenen satırdaki bir ismi düzeltmek yeter.
Derleme hatası olursa (ör. upstream bir alanı yeniden adlandırdı) genelde overlay/append içindeki isim düzeltilir.
Bu işi Claude'a da verebilirsin: log'daki hata satırı ve Nuvio-One commit'i yeterli.

## Eklenti nasıl bağlanıyor? (kısa mimari)
- **Veri taşıma:** `Stream`/`LocalScraperResult` sınıflarına alan eklenmez. Eklenti çalıştırıcısı bulduğu dublajları
  oynatma URL'siyle `StreamSidecarAudio` kayıt defterine yazar (1 kanca), oynatıcı aynı URL'yle okur.
- **Oynatıcı durumu:** `streamExternalAudios` ve iş (job) alanları `append/PlayerRuntimeController.members.txt` ile sınıfın
  sonuna eklenir. Alan değişince `mediaSourceFactory.dubExternalAudios` da güncellenir; bu yüzden `createMediaSource`
  çağrılarına argüman eklemek gerekmez.
- **Kaynak birleştirme:** `apply-hooks.py`, upstream'in `createMediaSource(...)` imzasını okuyup onu `createBaseMediaSource`
  olarak yeniden adlandırır ve **aynı imzayla** bir sarmalayıcı üretir (dublajı `MergingMediaSource` ile ekler).
  Upstream yeni parametre eklese de sarmalayıcı onu otomatik taşır.
- **Menü:** `AudioSelectionOverlay` içinde 2 satır (`DubAudioRows`), olaylar `DubUi` köprüsüyle doğrudan controller'a gider.
- **Kalan kancalar:** motor seçimi, ilk `STATE_READY`, ses çıkışı sarmalayıcısı, `applyStreamMetadata`, ses parçası etiketi.

## Sınırlar (bilmen gerekenler)
- Güncelleme "kod birleştirme" değil **APK yenileme**dir: derleme GitHub'da olur, uygulama sadece hazır APK'yı indirir.
- Kancalar yerleşmeden ve proje derlenmeden sürüm yayınlanmaz ama dublaj davranışını otomatik test eden bir test yok;
  Nuvio büyük bir oynatıcı yeniden yazımı yaparsa eklenti çalışmayabilir (derleme hatası olarak görürsün).
- `dublaj_kaynaklari.json` ayrı [`claaude8/dupiii`](https://github.com/claaude8/dupiii) deposundan çekilir (adres `core/dub/DubSourceManager.kt` içinde). Site değişince orayı güncellemek yeter, APK gerekmez.
