# Account connection assessment

Checked against the providers' public documentation on October 2, 2026. **Wealthy does not currently synchronize live bank, payment-service, or point balances.** Its financial-service screen links to provider information and states this limitation. Local wallet and point-card records are functional; those records are not evidence of account authorization.

## The intended user experience

The proposed flow is: choose a bank in Wealthy → authenticate and authorize on the provider's trusted screen → return to Wealthy → select which account corresponds to a wallet → receive balance updates with a visible update time. Users should not enter developer API keys. Bank authentication can open a bank app or a web authorization screen, depending on the bank's supported flow; launching the bank app itself is not authorization to read its data.

iOS isolates third-party apps. Access to another app's information requires an explicitly provided sharing mechanism; there is no general “read the balances of my installed apps” permission. [Apple platform security](https://support.apple.com/en-au/guide/security/sec15bfe098e/1/web/1).

## First banks and wider coverage

| Service | Verified public capability | What Wealthy still needs |
| --- | --- | --- |
| SBI Shinsei Bank | Moneytree lists it among banks with an API agreement. | Wealthy-specific provider enrollment, supported-account confirmation, consent integration and device testing. |
| DOCOMO SMTB Net Bank | The former SBI Sumishin Net Bank provides account-reference API access to Moneytree. The bank changed its name on August 3, 2026; a provider may still use the old label. | The same enrollment and verification, including current institution IDs and regional/account restrictions. |
| Other banks, cards and points | Moneytree LINK advertises more than 2,500 financial services and unified account/point APIs. | Confirm each service's actual LINK coverage; the advertised count does not establish support for every product or a particular account. |

Sources: [Moneytree bank API contracts](https://getmoneytree.com/contracts/api-type-a), [bank's Moneytree API announcement](https://www.netbk.co.jp/contents/company/press/2018/corp_news_20180319_02.html), [current bank-name guidance](https://help.netbk.co.jp/faq_detail.html?category=504&id=7836&page=1), [Moneytree LINK service coverage](https://getmoneytree.com/jp/link/link-api).

Moneytree LINK is the proposed first provider, based on its existing bank coverage and mobile consent SDK. Its mobile flow uses authorization-code OAuth with PKCE. Its production connection information is normally provided after a contract is signed. Installing the consumer Moneytree app or purchasing a consumer subscription does not itself issue credentials for Wealthy's developer integration. Current Wealthy-specific eligibility and the exact two banks' LINK coverage have **not** been confirmed with Moneytree. [SDK overview](https://docs.link.getmoneytree.com/docs/link-sdk-overview), [authorization flow](https://docs.link.getmoneytree.com/docs/product-and-tech-overview), [connection environments](https://docs.link.getmoneytree.com/docs/api-domain).

The provider charges an initial fee and a monthly usage fee. Amounts are not publicly specified; quotations follow a business discussion and an NDA. A 30-day free API staging trial is available, with a corporate-email requirement and possible suspension of applications using personal or mobile-carrier email addresses. Neither a Wealthy-specific quotation nor individual-developer eligibility has been obtained. [Official pricing FAQ](https://faq.getmoneytree.com/cost), [trial conditions](https://getmoneytree.com/jp/link/request-api-sandbox-trial).

## Payment services

| Service | Current finding |
| --- | --- |
| PayPay | A wallet-balance API exists, but requires merchant onboarding, additional balance-access approval and explicit user authorization with an appropriate scope. An installed PayPay app alone does not grant access. [Official balance API](https://www.paypay.ne.jp/opa/doc/jp/v1.0/get_balance.html). |
| Rakuten | The reviewed public Web Service catalog exposes shopping and related APIs; a personal bank, Pay or point-balance endpoint was not identified there. This is not proof that a private partner interface cannot exist. Bank/card/point products need individual provider coverage checks. [Public API catalog](https://webservice.rakuten.co.jp/documentation/). |
| GMO Aozora | Bank APIs exist, with an application and test process. Its published direct-connection policy currently limits production use to corporate customers; the experimental environment accepts individuals too. [Production policy](https://gmo-aozora.com/baas/api-cooperation/provisionpolicy.html). |

## Implementation after enrollment

The following work is proposed and is **not implemented**:

1. Register Wealthy's bundle ID, redirect URI and development/production client configuration with the provider; use the official mobile SDK and PKCE consent flow.
2. Store access credentials in Keychain, exclude them from backups, and support revocation and deletion. Request read-only account/point access; do not request transfer access.
3. Map provider account IDs to stable wallet identities. Keep point units separate from JPY and decline unsupported currencies rather than relabeling them as yen.
4. Store remote snapshot time and account status. Replace a balance snapshot rather than adding it. Reconcile pending local receipt entries against bank postings so synchronization cannot debit a receipt twice. Handle card liabilities separately from their repayment bank account.
5. Respect provider update limits and iOS background-execution limits. Show the actual last update rather than promising continuous real-time updates.
6. Verify authorization, return from bank apps, cancellation, expired consent, duplicate account connections and reconciliation on an Apple Intelligence-capable iPhone/iPad.

No financial-service password, live account data or provider secret has been requested, recorded, or placed in this repository. Provider enrollment and configuration are the current external dependency; local receipt bookkeeping and point-card management do not require them.
