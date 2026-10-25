import Foundation

nonisolated enum UITranslations {
    static let strings: [AppLanguage: [String: String]] = [
        .english: [
            "ok": "OK", "thinking": "Thinking…", "processedRecurringTitle": "Recurring items added",
            "moneyTip": "Money tip", "readingReceipt": "Reading receipt…", "receiptImageSaveFailed": "Could not save the receipt image. Please take another photo.",
            "calendar.today": "Today", "calendar.income": "In: %@", "calendar.expense": "Out: %@",
            "chart.type": "Type", "chart.daily": "Daily", "chart.category": "Category", "chart.dayAxis": "Day",
            "wallet.name": "Wallet Name", "wallet.initialBalance": "Initial Balance", "wallet.balance": "Balance", "common.color": "Color",
            "recurring.schedule": "Schedule", "recurring.targetWallet": "Target Wallet", "recurring.monthlyDay": "Every month on day %d",
            "category.empty": "No Categories", "error": "Error",
            "receipt.captureDateWarning": "The printed date could not be read, so the photo date was entered. Please correct it if needed.",
            "showAIAdvice": "Show money tip", "language.display": "Display language", "language.choose": "Choose your language",
            "settings.open": "Open Settings", "availability.checkAgain": "Check Again", "availability.unavailable": "Apple Intelligence is unavailable",
            "availability.reason.oldOS": "Apple Intelligence requires iOS 26 or later. Update iOS, then check again.",
            "availability.reason.deviceNotEligible": "This device does not support Apple Intelligence. Use a supported device.",
            "availability.reason.notEnabled": "Apple Intelligence is off. Enable it in Settings > Apple Intelligence & Siri.",
            "availability.reason.notReady": "Apple Intelligence is still preparing. Check again after setup finishes.",
            "availability.reason.unknown": "Availability could not be determined. Check Settings and try again.",
            "backup.description": "Save wallets, income, expenses, recurring items and categories as JSON. Choose whether to include receipt images. Chat history expires after 24 hours and is excluded. Restoring replaces your current records.",
            "backup.imageTitle": "Receipt image backup", "backup.imageSummary": "%1$d receipt images, %2$@ total. Include them in the backup?",
            "backup.imageSizeNote": "Including images in JSON increases its size by about 33%. Chat history is excluded.",
            "backup.missingImages": "%d images are unavailable. Choose “Records only”, or recover the originals before including images.",
            "backup.includeImages": "Include images", "backup.recordsOnly": "Records only"
        ],
        .japanese: [
            "ok": "OK", "thinking": "考えています…", "processedRecurringTitle": "固定収支を反映しました",
            "moneyTip": "お金のひとこと", "readingReceipt": "レシートを解析中…", "receiptImageSaveFailed": "レシート画像を保存できませんでした。もう一度撮影してください。",
            "calendar.today": "今日", "calendar.income": "収入: %@", "calendar.expense": "支出: %@",
            "chart.type": "種類", "chart.daily": "日別", "chart.category": "カテゴリ別", "chart.dayAxis": "日",
            "wallet.name": "財布の名前", "wallet.initialBalance": "初期残高", "wallet.balance": "残高", "common.color": "色",
            "recurring.schedule": "スケジュール", "recurring.targetWallet": "対象の財布", "recurring.monthlyDay": "毎月%d日",
            "category.empty": "カテゴリがありません", "error": "エラー",
            "receipt.captureDateWarning": "印字日付を読み取れなかったため、撮影日を仮入力しました。必要に応じて修正してください。",
            "showAIAdvice": "お金のひとことを表示", "language.display": "表示言語", "language.choose": "表示言語を選択",
            "settings.open": "設定を開く", "availability.checkAgain": "再確認", "availability.unavailable": "Apple Intelligenceを利用できません",
            "availability.reason.oldOS": "Apple IntelligenceにはiOS 26以降が必要です。iOSを更新してから再確認してください。",
            "availability.reason.deviceNotEligible": "このデバイスはApple Intelligenceに対応していません。対応デバイスをご利用ください。",
            "availability.reason.notEnabled": "Apple Intelligenceがオフです。「設定」>「Apple IntelligenceとSiri」で有効にしてください。",
            "availability.reason.notReady": "Apple Intelligenceの準備中です。準備が完了してから再確認してください。",
            "availability.reason.unknown": "利用できるか確認できませんでした。設定を確認して、もう一度お試しください。",
            "backup.description": "財布、収入、支出、固定収支、カテゴリをJSONで保存します。レシート画像を含めるか選べます。チャット履歴は24時間で削除され、バックアップには含まれません。復元すると現在の記録は置き換わります。",
            "backup.imageTitle": "レシート画像のバックアップ", "backup.imageSummary": "レシート画像は%d枚、合計%@です。画像もバックアップに含めますか？",
            "backup.imageSizeNote": "画像をJSONに含めると、容量は約33%増えます。チャット履歴は含まれません。",
            "backup.missingImages": "読み取れない画像が%d枚あります。画像を含めるには元画像が必要です。「記録のみ」を選んでください。",
            "backup.includeImages": "画像も含める", "backup.recordsOnly": "記録のみ"
        ],
        .spanish: [
            "ok": "Aceptar", "thinking": "Pensando…", "processedRecurringTitle": "Movimientos recurrentes añadidos",
            "moneyTip": "Consejo financiero", "readingReceipt": "Leyendo recibo…", "receiptImageSaveFailed": "No se pudo guardar la imagen del recibo. Haz otra foto.",
            "calendar.today": "Hoy", "calendar.income": "Ingresos: %@", "calendar.expense": "Gastos: %@",
            "chart.type": "Tipo", "chart.daily": "Diario", "chart.category": "Categoría", "chart.dayAxis": "Día",
            "wallet.name": "Nombre de la cartera", "wallet.initialBalance": "Saldo inicial", "wallet.balance": "Saldo", "common.color": "Color",
            "recurring.schedule": "Programación", "recurring.targetWallet": "Cartera de destino", "recurring.monthlyDay": "Cada mes, el día %d",
            "category.empty": "No hay categorías", "error": "Error",
            "receipt.captureDateWarning": "No se pudo leer la fecha impresa, así que se introdujo la fecha de la foto. Corrígela si es necesario.",
            "showAIAdvice": "Mostrar consejo financiero", "language.display": "Idioma de visualización", "language.choose": "Elige el idioma",
            "settings.open": "Abrir ajustes", "availability.checkAgain": "Volver a comprobar", "availability.unavailable": "Apple Intelligence no está disponible",
            "availability.reason.oldOS": "Apple Intelligence requiere iOS 26 o posterior. Actualiza iOS y vuelve a comprobarlo.",
            "availability.reason.deviceNotEligible": "Este dispositivo no admite Apple Intelligence. Usa un dispositivo compatible.",
            "availability.reason.notEnabled": "Apple Intelligence está desactivado. Actívalo en Ajustes > Apple Intelligence y Siri.",
            "availability.reason.notReady": "Apple Intelligence aún se está preparando. Vuelve a comprobarlo cuando termine la configuración.",
            "availability.reason.unknown": "No se pudo determinar la disponibilidad. Revisa los ajustes e inténtalo de nuevo.",
            "backup.description": "Guarda carteras, ingresos, gastos, movimientos recurrentes y categorías en JSON. Elige si quieres incluir las imágenes de recibos. El historial del chat se elimina tras 24 horas y no se incluye. Al restaurar se sustituyen los registros actuales.",
            "backup.imageTitle": "Copia de seguridad de imágenes", "backup.imageSummary": "%d imágenes de recibos, %@ en total. ¿Incluirlas en la copia?",
            "backup.imageSizeNote": "Incluir imágenes en JSON aumenta su tamaño aproximadamente un 33%. El historial del chat queda excluido.",
            "backup.missingImages": "No se pueden leer %d imágenes. Elige «Solo registros» o recupera los originales antes de incluirlas.",
            "backup.includeImages": "Incluir imágenes", "backup.recordsOnly": "Solo registros"
        ],
        .korean: [
            "ok": "확인", "thinking": "생각 중…", "processedRecurringTitle": "정기 거래를 반영했습니다",
            "moneyTip": "재정 팁", "readingReceipt": "영수증을 읽는 중…", "receiptImageSaveFailed": "영수증 이미지를 저장하지 못했습니다. 다시 촬영해 주세요.",
            "calendar.today": "오늘", "calendar.income": "수입: %@", "calendar.expense": "지출: %@",
            "chart.type": "유형", "chart.daily": "일별", "chart.category": "카테고리별", "chart.dayAxis": "일",
            "wallet.name": "지갑 이름", "wallet.initialBalance": "초기 잔액", "wallet.balance": "잔액", "common.color": "색상",
            "recurring.schedule": "일정", "recurring.targetWallet": "대상 지갑", "recurring.monthlyDay": "매월 %d일",
            "category.empty": "카테고리가 없습니다", "error": "오류",
            "receipt.captureDateWarning": "영수증에 인쇄된 날짜를 읽지 못해 촬영 날짜를 임시로 입력했습니다. 필요하면 수정해 주세요.",
            "showAIAdvice": "재정 팁 표시", "language.display": "표시 언어", "language.choose": "표시 언어 선택",
            "settings.open": "설정 열기", "availability.checkAgain": "다시 확인", "availability.unavailable": "Apple Intelligence를 사용할 수 없습니다",
            "availability.reason.oldOS": "Apple Intelligence를 사용하려면 iOS 26 이상이 필요합니다. iOS를 업데이트한 후 다시 확인하세요.",
            "availability.reason.deviceNotEligible": "이 기기는 Apple Intelligence를 지원하지 않습니다. 지원되는 기기를 사용하세요.",
            "availability.reason.notEnabled": "Apple Intelligence가 꺼져 있습니다. 설정 > Apple Intelligence 및 Siri에서 켜세요.",
            "availability.reason.notReady": "Apple Intelligence가 아직 준비 중입니다. 설정이 끝난 후 다시 확인하세요.",
            "availability.reason.unknown": "사용 가능 여부를 확인할 수 없습니다. 설정을 확인한 후 다시 시도하세요.",
            "backup.description": "지갑, 수입, 지출, 정기 거래 및 카테고리를 JSON으로 저장합니다. 영수증 이미지를 포함할지 선택할 수 있습니다. 채팅 기록은 24시간 후 삭제되며 백업에 포함되지 않습니다. 복원하면 현재 기록이 대체됩니다.",
            "backup.imageTitle": "영수증 이미지 백업", "backup.imageSummary": "영수증 이미지 %d개, 총 %@입니다. 백업에 포함할까요?",
            "backup.imageSizeNote": "JSON에 이미지를 포함하면 크기가 약 33% 늘어납니다. 채팅 기록은 제외됩니다.",
            "backup.missingImages": "사용할 수 없는 이미지가 %d개 있습니다. “기록만”을 선택하거나 원본을 복구한 후 이미지를 포함해 주세요.",
            "backup.includeImages": "이미지 포함", "backup.recordsOnly": "기록만"
        ],
    ]

    static func jpy(_ amount: Int, language: AppLanguage) -> String {
        let formatter = NumberFormatter()
        formatter.locale = language.locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "¥" + (formatter.string(from: NSNumber(value: amount)) ?? String(amount))
    }
}
