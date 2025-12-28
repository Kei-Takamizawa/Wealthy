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
    // Tab Bar specific keys if needed, but existing ones might suffice
    case home
    // Missing keys
    case noExpenses, noExpensesDesc, noData
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    // ■ 修正: @Published + UserDefaults で確実に変更を通知するようにしました
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
    
    // 辞書データ
    private let translations: [AppLanguage: [L10n: String]] = [
        .japanese: [
            .home: "ホーム", .totalAssets: "総資産", .scan: "スキャン", .deposit: "入金", .history: "最近の活動",
            .wallets: "資産・設定", .analysis: "分析", .calendar: "カレンダー", .settings: "設定",
            .income: "収入", .expense: "支出", .category: "カテゴリ", .date: "日付",
            .save: "保存", .cancel: "キャンセル", .edit: "編集", .recurring: "固定収支設定",
            .add: "追加", .delete: "削除",
            .noExpenses: "支出なし", .noExpensesDesc: "この日の支出はありません", .noData: "データがありません"
        ],
        .english: [
            .home: "Home", .totalAssets: "Total Assets", .scan: "SCAN", .deposit: "DEPOSIT", .history: "Recent Activity",
            .wallets: "Wallets", .analysis: "Analysis", .calendar: "Calendar", .settings: "Settings",
            .income: "Income", .expense: "Expense", .category: "Category", .date: "Date",
            .save: "Save", .cancel: "Cancel", .edit: "Edit", .recurring: "Recurring Rules",
            .add: "Add", .delete: "Delete",
            .noExpenses: "No Expenses", .noExpensesDesc: "No expenses for this day", .noData: "No data available"
        ],
        .spanish: [
            .home: "Inicio", .totalAssets: "Activos Totales", .scan: "ESCANEAR", .deposit: "DEPÓSITO", .history: "Actividad Reciente",
            .wallets: "Billeteras", .analysis: "Análisis", .calendar: "Calendario", .settings: "Ajustes",
            .income: "Ingresos", .expense: "Gastos", .category: "Categoría", .date: "Fecha",
            .save: "Guardar", .cancel: "Cancelar", .edit: "Editar", .recurring: "Pagos Recurrentes",
            .add: "Añadir", .delete: "Eliminar",
            .noExpenses: "Sin Gastos", .noExpensesDesc: "No hay gastos para este día", .noData: "No hay datos disponibles"
        ],
        .korean: [
            .home: "홈", .totalAssets: "총 자산", .scan: "스캔", .deposit: "입금", .history: "최근 활동",
            .wallets: "지갑", .analysis: "분석", .calendar: "달력", .settings: "설정",
            .income: "수입", .expense: "지출", .category: "카테고리", .date: "날짜",
            .save: "저장", .cancel: "취소", .edit: "편집", .recurring: "반복 설정",
            .add: "추가", .delete: "삭제",
            .noExpenses: "지출 없음", .noExpensesDesc: "이 날의 지출이 없습니다", .noData: "데이터 없음"
        ],
        .italian: [
            .home: "Home", .totalAssets: "Patrimonio Totale", .scan: "SCANSIONA", .deposit: "DEPOSITO", .history: "Attività Recente",
            .wallets: "Portafogli", .analysis: "Analisi", .calendar: "Calendario", .settings: "Impostazioni",
            .income: "Entrate", .expense: "Uscite", .category: "Categoria", .date: "Data",
            .save: "Salva", .cancel: "Annulla", .edit: "Modifica", .recurring: "Pagamenti Ricorrenti",
            .add: "Aggiungi", .delete: "Elimina",
            .noExpenses: "Nessuna Spesa", .noExpensesDesc: "Nessuna spesa per questo giorno", .noData: "Nessun dato disponibile"
        ],
        .arabic: [
            .home: "الرئيسية", .totalAssets: "إجمالي الأصول", .scan: "مسح ضوئي", .deposit: "إيداع", .history: "النشاط الأخير",
            .wallets: "المحافظ", .analysis: "تحليل", .calendar: "التقويم", .settings: "الإعدادات",
            .income: "دخل", .expense: "مصروف", .category: "فئة", .date: "تاريخ",
            .save: "حفظ", .cancel: "إلغاء", .edit: "تعديل", .recurring: "قواعد متكررة",
            .add: "إضافة", .delete: "حذف",
            .noExpenses: "لا توجد مصاريف", .noExpensesDesc: "لا توجد مصاريف لهذا اليوم", .noData: "لا توجد بيانات متاحة"
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

