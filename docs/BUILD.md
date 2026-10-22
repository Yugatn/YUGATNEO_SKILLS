# Сборка iOS-приложения

Это реальный исходный SwiftUI-код, а не только концепция. На главной странице репозитория открыть `Sources/YugatnNeoSkills/`.

На Mac с Xcode и XcodeGen:

```sh
git clone https://github.com/Yugatn/YUGATNEO_SKILLS.git
cd YUGATNEO_SKILLS
brew install xcodegen
xcodegen generate
open YugatnNeoSkills.xcodeproj
```

Выбрать симулятор iPhone и запустить схему `YugatnNeoSkills`. Для физического iPhone нужна настройка подписи команды Apple. Для HealthKit необходим доступ к соответствующей capability в настройках подписи. В GitHub Actions добавлена проверка сборки — считать приложение проверенным можно только после успешного CI.

SwiftUI сейчас реализован только для iOS; Android, Windows, Linux и macOS пока запланированы. Камера и HealthKit — экспериментальные интеграции, не валидированная система оценки правильности выполнения движений.
