# Tek promptla kurulum

Kurulumdan önce şu ajanlar kurulu olmalı:

- **OpenCode** — orkestratör.
- **Codex CLI, Claude Code ve Crush** — alt ajanlar.
- **Python 3, Node.js ve git** — temel çalışma ortamı.

Aşağıdaki metni ajanına yapıştır.

```text
Sen bir kurulum ajanısın. Aşağıdaki adımları tam olarak ve sırayla uygula. Kendi başına alternatif yöntem, ek araç veya ek görev seçme. Bir adım başarısız olursa dur ve kısa bir hata raporu ver.

0. Repo adresi: https://github.com/zehedisode/orkestra. Bu adresi kullan.
1. Repoyu klonla ve dizine gir:
   git clone "https://github.com/zehedisode/orkestra" orkestra
   cd orkestra
2. Kurulumu çalıştır:
   bash install.sh
   sudo kullanma. Ajan CLI'lerini kurmaya çalışma; eksikse raporda belirt.
3. Eksik anahtarları belirle ve sor:
   - `worker doctor` çalıştır; komut bulunamazsa `"$HOME/.local/bin/worker" doctor` kullan.
   - Yalnızca eksik olan anahtarı kullanıcıya sor. Anahtarı sohbete yazmasını isteme; kendi terminalinde ortam değişkeni olarak tanımlamasını veya yerel bir dosyaya yazmasını söyle.
   - `OPENCODE_GO_KEY`: https://opencode.ai/console/go adresindeki Go aboneliğinden alınır. Kalıcı seçenek: `OPENCODE_GO_KEY=...` satırını `~/.config/opencode-go-proxy.env` dosyasına yaz ve `chmod 600` uygula.
   - `COMMANDCODE_API_KEY`: https://commandcode.ai/settings/keys adresinden alınır veya `commandcode login` ile `~/.commandcode/auth.json` oluşturulur.
   - Kullanıcı anahtarı hazırladığını söyleyince devam et. Anahtarı repoya, AGENTS.md dosyasına veya loga yazma; ekrana da basma.
4. Doğrula:
   - `worker doctor` komutunu yeniden çalıştır.
   - Eksik varsa 3. adıma dön. Yalnızca doctor sonucunu doğrula; örnek görev çalıştırma.
5. Kısa rapor ver (en fazla 6 satır):
   - klonlanan dizin
   - install.sh sonucu
   - worker doctor geçen/kalan sayısı
   - eksik anahtar veya ajan (varsa)
   - sonraki komut: worker status
Ham komut çıktısını yapıştırma.
```
