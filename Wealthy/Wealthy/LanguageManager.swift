//
//  LanguageManager.swift
//  Wealthy
//
//  Created by Harrison on 12/27/25.
//

import Foundation
import Combine
import SwiftUI

// 言語の種類の定義
enum AppLanguage: String, CaseIterable, Identifiable {
    case japanese = "日本語"
    case english = "English"
    case spanish = "Español"
    case korean = "한국어"
    case italian = "Italiano"
    case arabic = "العربية"

    
    var id: String { self.rawValue }
}

// 翻訳キー
enum L10n: String {
    case totalAssets, scan, deposit, history, wallets, analysis, calendar, settings
    case income, expense, category, date, save, cancel, edit, recurring, add, delete
    case home
    case noExpenses, noExpensesDesc, noData
    
    // New Keys
    case tapToExpand, loading
    case shopName, amount, wallet, selectWallet
    case editTitle, done, close
    case depositTitle, depositInfo, details, dateLabel
    case categorySettings, newCategory, categoryName, icon, color, basicInfo
    case recurringSettings, noRecurringItems, recurringDesc, newRule, type, monthlyDate, targetWallet
    case unclassified, unselected
    // Default Category Names (for translation mapping)
    case catFood, catTransport, catDaily, catHobby, catClothing, catOthers
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let savedLang = UserDefaults.standard.string(forKey: "selectedLanguage") ?? AppLanguage.japanese.rawValue
        self.currentLanguage = AppLanguage(rawValue: savedLang) ?? .japanese
        
        $currentLanguage
            .dropFirst()
            .sink { lang in
                UserDefaults.standard.set(lang.rawValue, forKey: "selectedLanguage")
            }
            .store(in: &cancellables)
    }
    
    // カテゴリ名の翻訳マッピング (DBの生データ -> L10nキー)
    private let categoryMapping: [String: L10n] = [
        "食費": .catFood, "Food": .catFood, "Comida": .catFood, "식비": .catFood, "Cibo": .catFood, "طعام": .catFood,
        "交通費": .catTransport, "Transport": .catTransport, "Transporte": .catTransport, "교통비": .catTransport, "Trasporti": .catTransport, "نقل": .catTransport,
        "日用品": .catDaily, "Daily": .catDaily, "Diario": .catDaily, "생필품": .catDaily, "Quotidiano": .catDaily, "يومي": .catDaily,
        "趣味": .catHobby, "Hobby": .catHobby, "Afición": .catHobby, "취미": .catHobby, "هواية": .catHobby,
        "衣服": .catClothing, "Clothing": .catClothing, "Ropa": .catClothing, "의류": .catClothing, "Vestiti": .catClothing, "ملابس": .catClothing,
        "その他": .catOthers, "Others": .catOthers, "Otros": .catOthers, "기타": .catOthers, "Altro": .catOthers, "أخرى": .catOthers
    ]
    
    func translateCategory(name: String) -> String {
        if let key = categoryMapping[name] {
            return t(key)
        }
        return name
    }
    
    // 辞書データ
    private let translations: [AppLanguage: [L10n: String]] = [
        .japanese: [
            .home: "ホーム", .totalAssets: "総資産", .scan: "スキャン", .deposit: "入金", .history: "最近の活動",
            .wallets: "資産・設定", .analysis: "分析", .calendar: "カレンダー", .settings: "設定",
            .income: "収入", .expense: "支出", .category: "カテゴリ", .date: "日付",
            .save: "保存", .cancel: "キャンセル", .edit: "編集", .recurring: "固定収支設定",
            .add: "追加", .delete: "削除",
            .noExpenses: "支出なし", .noExpensesDesc: "この日の支出はありません", .noData: "データがありません",
            
            .tapToExpand: "タップして拡大", .loading: "読み込み中...",
            .shopName: "店名", .amount: "金額", .wallet: "財布", .selectWallet: "財布を選択",
            .editTitle: "編集", .done: "完了", .close: "閉じる",
            .depositTitle: "資金の追加", .depositInfo: "入金情報", .details: "詳細", .dateLabel: "日付",
            .categorySettings: "カテゴリ設定", .newCategory: "新規カテゴリ", .categoryName: "カテゴリ名", .icon: "アイコン", .color: "カラー", .basicInfo: "基本情報",
            .recurringSettings: "固定収支の設定", .noRecurringItems: "固定収支なし", .recurringDesc: "毎月の固定給やサブスクを登録しよう", .newRule: "新規ルール作成", .type: "タイプ", .monthlyDate: "毎月の日付", .targetWallet: "対象の財布",
            .unclassified: "未分類", .unselected: "未選択",
            
            .catFood: "食費", .catTransport: "交通費", .catDaily: "日用品", .catHobby: "趣味", .catClothing: "衣服", .catOthers: "その他"
        ],
        .english: [
            .home: "Home", .totalAssets: "Total Assets", .scan: "SCAN", .deposit: "DEPOSIT", .history: "Recent Activity",
            .wallets: "Wallets", .analysis: "Analysis", .calendar: "Calendar", .settings: "Settings",
            .income: "Income", .expense: "Expense", .category: "Category", .date: "Date",
            .save: "Save", .cancel: "Cancel", .edit: "Edit", .recurring: "Recurring Rules",
            .add: "Add", .delete: "Delete",
            .noExpenses: "No Expenses", .noExpensesDesc: "No expenses for this day", .noData: "No data available",
            
            .tapToExpand: "Tap to expand", .loading: "Loading...",
            .shopName: "Shop Name", .amount: "Amount", .wallet: "Wallet", .selectWallet: "Select Wallet",
            .editTitle: "Edit", .done: "Done", .close: "Close",
            .depositTitle: "Add Funds", .depositInfo: "Deposit Info", .details: "Details", .dateLabel: "Date",
            .categorySettings: "Categories", .newCategory: "New Category", .categoryName: "Category Name", .icon: "Icon", .color: "Color", .basicInfo: "Basic Info",
            .recurringSettings: "Recurring Settings", .noRecurringItems: "No Recurring Items", .recurringDesc: "Register monthly salary or subscriptions", .newRule: "New Rule", .type: "Type", .monthlyDate: "Day of Month", .targetWallet: "Target Wallet",
            .unclassified: "Unclassified", .unselected: "Unselected",
            
            .catFood: "Food", .catTransport: "Transport", .catDaily: "Daily", .catHobby: "Hobby", .catClothing: "Clothing", .catOthers: "Others"
        ],
        .spanish: [
            .home: "Inicio", .totalAssets: "Activos Totales", .scan: "ESCANEAR", .deposit: "DEPÓSITO", .history: "Actividad Reciente",
            .wallets: "Billeteras", .analysis: "Análisis", .calendar: "Calendario", .settings: "Ajustes",
            .income: "Ingresos", .expense: "Gastos", .category: "Categoría", .date: "Fecha",
            .save: "Guardar", .cancel: "Cancelar", .edit: "Editar", .recurring: "Pagos Recurrentes",
            .add: "Añadir", .delete: "Eliminar",
            .noExpenses: "Sin Gastos", .noExpensesDesc: "No hay gastos para este día", .noData: "No hay datos disponibles",
            
            .tapToExpand: "Tocar para ampliar", .loading: "Cargando...",
            .shopName: "Nombre Tienda", .amount: "Cantidad", .wallet: "Billetera", .selectWallet: "Seleccionar Billetera",
            .editTitle: "Editar", .done: "Listo", .close: "Cerrar",
            .depositTitle: "Añadir Fondos", .depositInfo: "Info Depósito", .details: "Detalles", .dateLabel: "Fecha",
            .categorySettings: "Categorías", .newCategory: "Nueva Categoría", .categoryName: "Nombre", .icon: "Icono", .color: "Color", .basicInfo: "Info Básica",
            .recurringSettings: "Ajustes Recurrentes", .noRecurringItems: "Sin Items Recurrentes", .recurringDesc: "Registra salario o suscripciones", .newRule: "Nueva Regla", .type: "Tipo", .monthlyDate: "Día del Mes", .targetWallet: "Billetera Destino",
            .unclassified: "Sin Clasificar", .unselected: "No Seleccionado",
            
            .catFood: "Comida", .catTransport: "Transporte", .catDaily: "Diario", .catHobby: "Afición", .catClothing: "Ropa", .catOthers: "Otros"
        ],
        .korean: [
            .home: "홈", .totalAssets: "총 자산", .scan: "스캔", .deposit: "입금", .history: "최근 활동",
            .wallets: "지갑", .analysis: "분석", .calendar: "달력", .settings: "설정",
            .income: "수입", .expense: "지출", .category: "카테고리", .date: "날짜",
            .save: "저장", .cancel: "취소", .edit: "편집", .recurring: "반복 설정",
            .add: "추가", .delete: "삭제",
            .noExpenses: "지출 없음", .noExpensesDesc: "이 날의 지출이 없습니다", .noData: "데이터 없음",
            
            .tapToExpand: "탭하여 확대", .loading: "로딩 중...",
            .shopName: "가게 이름", .amount: "금액", .wallet: "지갑", .selectWallet: "지갑 선택",
            .editTitle: "편집", .done: "완료", .close: "닫기",
            .depositTitle: "자금 추가", .depositInfo: "입금 정보", .details: "상세", .dateLabel: "날짜",
            .categorySettings: "카테고리 설정", .newCategory: "새 카테고리", .categoryName: "카테고리명", .icon: "아이콘", .color: "색상", .basicInfo: "기본 정보",
            .recurringSettings: "고정 수지 설정", .noRecurringItems: "고정 수지 없음", .recurringDesc: "월급이나 구독을 등록하세요", .newRule: "새 규칙", .type: "유형", .monthlyDate: "매월 날짜", .targetWallet: "대상 지갑",
            .unclassified: "미분류", .unselected: "미선택",
            
            .catFood: "식비", .catTransport: "교통비", .catDaily: "생필품", .catHobby: "취미", .catClothing: "의류", .catOthers: "기타"
        ],
        .italian: [
            .home: "Home", .totalAssets: "Patrimonio Totale", .scan: "SCANSIONA", .deposit: "DEPOSITO", .history: "Attività Recente",
            .wallets: "Portafogli", .analysis: "Analisi", .calendar: "Calendario", .settings: "Impostazioni",
            .income: "Entrate", .expense: "Uscite", .category: "Categoria", .date: "Data",
            .save: "Salva", .cancel: "Annulla", .edit: "Modifica", .recurring: "Pagamenti Ricorrenti",
            .add: "Aggiungi", .delete: "Elimina",
            .noExpenses: "Nessuna Spesa", .noExpensesDesc: "Nessuna spesa per questo giorno", .noData: "Nessun dato disponibile",
            
            .tapToExpand: "Tocca per ingrandire", .loading: "Caricamento...",
            .shopName: "Nome Negozio", .amount: "Importo", .wallet: "Portafoglio", .selectWallet: "Seleziona Portafoglio",
            .editTitle: "Modifica", .done: "Fatto", .close: "Chiudi",
            .depositTitle: "Aggiungi Fondi", .depositInfo: "Info Deposito", .details: "Dettagli", .dateLabel: "Data",
            .categorySettings: "Categorie", .newCategory: "Nuova Categoria", .categoryName: "Nome Categoria", .icon: "Icona", .color: "Colore", .basicInfo: "Info Base",
            .recurringSettings: "Impostazioni Ricorrenti", .noRecurringItems: "Nessuna Voce", .recurringDesc: "Registra stipendio o abbonamenti", .newRule: "Nuova Regola", .type: "Tipo", .monthlyDate: "Giorno del Mese", .targetWallet: "Portafoglio Dest.",
            .unclassified: "Non Classificato", .unselected: "Non Selezionato",
            
            .catFood: "Cibo", .catTransport: "Trasporti", .catDaily: "Quotidiano", .catHobby: "Hobby", .catClothing: "Vestiti", .catOthers: "Altro"
        ],
        .arabic: [
            .home: "الرئيسية", .totalAssets: "إجمالي الأصول", .scan: "مسح ضوئي", .deposit: "إيداع", .history: "النشاط الأخير",
            .wallets: "المحافظ", .analysis: "تحليل", .calendar: "التقويم", .settings: "الإعدادات",
            .income: "دخل", .expense: "مصروف", .category: "فئة", .date: "تاريخ",
            .save: "حفظ", .cancel: "إلغاء", .edit: "تعديل", .recurring: "قواعد متكررة",
            .add: "إضافة", .delete: "حذف",
            .noExpenses: "لا توجد مصاريف", .noExpensesDesc: "لا توجد مصاريف لهذا اليوم", .noData: "لا توجد بيانات متاحة",
            
            .tapToExpand: "اضغط للتوسيع", .loading: "جار التحميل...",
            .shopName: "اسم المتجر", .amount: "المبلغ", .wallet: "المحفظة", .selectWallet: "اختر المحفظة",
            .editTitle: "تعديل", .done: "تم", .close: "إغلاق",
            .depositTitle: "إضافة أموال", .depositInfo: "معلومات الإيداع", .details: "التفاصيل", .dateLabel: "التاريخ",
            .categorySettings: "الإعدادات الفئوية", .newCategory: "فئة جديدة", .categoryName: "اسم الفئة", .icon: "أيقونة", .color: "لون", .basicInfo: "معلومات أساسية",
            .recurringSettings: "الإعدادات المتكررة", .noRecurringItems: "لا توجد عناصر", .recurringDesc: "سجل راتب شهري أو اشتراكات", .newRule: "قاعدة جديدة", .type: "نوع", .monthlyDate: "يوم في الشهر", .targetWallet: "المحفظة المستهدفة",
            .unclassified: "غير مصنف", .unselected: "غير محدد",
            
            .catFood: "طعام", .catTransport: "نقل", .catDaily: "يومي", .catHobby: "هواية", .catClothing: "ملابس", .catOthers: "أخرى"
        ]
    ]
    
    func t(_ key: L10n) -> String {
        return translations[currentLanguage]?[key] ?? "???"
    }
    
    var currencySymbol: String {
        switch currentLanguage {

        default: return "¥"
        }
    }
}

