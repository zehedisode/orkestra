# Günlük kullanım

Örnekler hedef projeyi `-C` ile gösterir ve komutları repo dışından çalıştırır.

## Durumu gör

```bash
worker status
```

Hangi ajan kurulu, hangi model seçili ve anahtarlar okunuyor mu gösterir. Sorun varsa önce `worker doctor` çalıştır.

## Plan çıkar

```bash
worker plan -C ~/projects/app "Ödeme akışındaki hata durumlarını incele; dosya değiştirmeden uygulanabilir bir plan çıkar."
```

Claude salt-okunur çalışır; analiz ve ikinci görüş için uygundur.

## Kod yaz

```bash
worker code -C ~/projects/app -w login-fix "Giriş formunda boş e-posta hatasını düzelt ve ilgili testi güncelle."
```

Codex çalışır ve değişiklikleri ayrı git worktree'de yapar. `-w` kullanmazsan hedef dizinde doğrudan yazar; önce diff'i incele.

## Kodu incele

```bash
worker review -C ~/projects/app "Son değişiklikleri hata, güvenlik ve test kapsamı açısından incele; bulguları önem sırasıyla yaz."
```

Claude salt-okunur çalışır. Codex'ten sonra ayrı bir doğrulama adımı olarak kullan.

## Orkestratöre devret

```bash
worker ask -C ~/projects/app "Kullanıcı profilindeki yavaş sorguyu araştır, planı çıkar ve düzeltmeyi uygula."
```

OpenCode orkestratörü görevi Codex, Claude ve Crush arasında böler. Tek seferlik çalışır; belirsizlikleri görev metnine ekle.

## Geçmişi listele

```bash
worker runs -n 10
```

Son koşuların durumunu, süresini ve ajanını gösterir. Ayrıntı için ilgili `~/.agent/runs/<run>/` dizinindeki `output.log`, `meta.json` ve varsa `diff.patch` dosyasına bak.
