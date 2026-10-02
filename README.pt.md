# Wealthy

[English](README.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md) · [हिन्दी](README.hi.md) · [Español](README.es.md) · [العربية](README.ar.md) · [Français](README.fr.md) · [Bahasa Indonesia](README.id.md) · [한국어](README.ko.md) · [Русский](README.ru.md) · [Português](README.pt.md)

Wealthy é um aplicativo para iPhone e iPad que registra despesas, receitas e saldos de carteiras. A leitura de recibos, os resumos de gastos e a IA no dispositivo ajudam a revisar suas finanças.

## Recursos

- Registrar receitas e despesas por carteira e categoria.
- Digitalizar recibos, conferir os detalhes e guardar as imagens originais.
- Consultar transações no calendário e despesas por categoria.
- Aplicar lançamentos mensais recorrentes ao abrir o aplicativo.
- Fazer perguntas sobre seus registros ao Apple Foundation Models.
- Ler dicas curtas com humor leve, baseadas nas receitas, despesas e ativos registrados.
- Exportar e restaurar registros financeiros, com imagens de recibos opcionais.
- Registrar ativos e operações em várias moedas, mantendo os saldos separados.


## Várias moedas

- São aceitas **155 moedas ISO 4217 ativas**, com base na lista da SIX publicada em 2026-09-17.
- Na primeira abertura, depois de escolher o idioma da interface, selecione uma ou mais moedas para ativar. Em **Início → Ajustes**, edite as moedas ativas e escolha a moeda padrão para novos lançamentos.
- Ativos e histórico de operações mantêm a moeda salva em cada registro. Os saldos ficam separados e Análise permite alternar entre as moedas ativas. Não há conversão automática de câmbio.
- Os valores são armazenados em unidades menores ISO: JPY tem 0 casas decimais, USD 2 e KWD 3. Os registros existentes continuam em JPY.
- O OCR de recibos permanece igual: destina-se a textos em japonês e inglês e extrai automaticamente valores inteiros em JPY. Valores em moeda estrangeira exigem entrada e conferência manual.

## Métodos de pagamento e cartões de pontos

O recibo sugere a carteira correspondente ao método de pagamento impresso; sem indicação, usa Dinheiro. A confirmação desconta o valor uma vez. Uma carteira ausente é criada com saldo zero e fica negativa, por exemplo `¥0 → ¥-1,200`. Editar ou excluir um registro ajusta o saldo. Vários métodos, pontos resgatados ou várias carteiras correspondentes exigem revisão manual. São regras sobre texto OCR; a precisão do método de pagamento em fotos não foi medida.

Em **Carteiras**, edite uma carteira criada automaticamente para definir o saldo atual ou registre um saldo inicial somado ao saldo registrado. Cartões de pontos podem ter nome, número de associado opcional, saldo e validade opcional. Os pontos são inseridos manualmente, separados dos ativos monetários e incluídos nos backups financeiros.

A sincronização automática com bancos e serviços de pagamento **não está implementada**. As primeiras integrações propostas são SBI Shinsei Bank e DOCOMO SMTB Net Bank, antigo SBI Sumishin Net Bank. A permissão para abrir um aplicativo bancário não permite ler seu saldo; é necessário um serviço autorizado de compartilhamento de contas. Consulte a [avaliação de integração](Documentation/FinancialServiceIntegration.md).

## Requisitos

São necessários **iOS ou iPadOS 26.0 ou posterior** e um **dispositivo compatível com Apple Intelligence**. O Apple Intelligence deve estar ativado e seu modelo do sistema pronto antes de usar o aplicativo.

| Dispositivo | Hardware compatível |
| --- | --- |
| iPhone | iPhone 15 Pro / Pro Max, modelos iPhone 16 e posteriores, ou iPhone Air |
| iPad | Modelos com M1 ou posterior, ou iPad mini com A17 Pro |

As restrições de idioma e região da Apple também se aplicam. Wealthy verifica a disponibilidade do modelo ao iniciar e ao voltar ao primeiro plano. Consulte os [requisitos atuais da Apple](https://www.apple.com/apple-intelligence/).

## Como usar

1. Ative Apple Intelligence em **Ajustes → Apple Intelligence e Siri** e aguarde a preparação do modelo.
2. Escolha um dos **11 idiomas da interface** na janela da primeira abertura. O padrão é inglês e sua escolha é salva. Altere depois em **Início → Ajustes → Ajustes de idioma**. A interface em árabe usa direção da direita para a esquerda.
3. Selecione uma ou mais moedas para ativar. Depois, você pode editar as moedas ativas e escolher a moeda padrão para novos lançamentos em **Início → Ajustes**.
4. Adicione uma carteira e registre receitas ou digitalize um recibo. Confira os detalhes antes de salvar.
5. Consulte Calendário e Análise ou abra o assistente de IA para perguntar sobre seus registros.

Os idiomas da interface são inglês, japonês, chinês simplificado, hindi, espanhol, árabe, francês, indonésio, coreano, russo e português. A lista refere-se à interface e a estas edições do README; não significa que o modelo Apple instalado aceite todos os 11 idiomas.

## IA no dispositivo

Conversa, extração complementar de recibos e comentários curtos de gastos usam o **SystemLanguageModel** integrado da Apple. O sistema operacional gerencia o modelo e suas atualizações. Não há outros modelos, telas de download ou seleção de modelo, nem conexão com Private Cloud Compute ou outro provedor de IA na nuvem.

A conversa solicita uma resposta no idioma da mensagem mais recente, independentemente da interface. Se o idioma da entrada não puder ser identificado, usa o idioma da interface. Os idiomas aceitos dependem do modelo Apple instalado. Idiomas de conversa não aceitos geram uma mensagem explícita: tente um idioma aceito por esse modelo. Comentários sobre gastos solicitam o idioma da interface e combinam uma piada escrita pela IA com uma ação baseada nos registros; quando não é possível gerar, uma dica local é usada.

## Registros, recibos e backup

Os registros financeiros e as imagens de recibos ficam no dispositivo. Em **Início → Ajustes → Gerenciamento de dados**, exporte carteiras, receitas, despesas, lançamentos recorrentes e categorias em JSON. Uma janela mostra o tamanho das imagens referenciadas e permite incluí-las ou exportar só os registros. Imagens compartilhadas são incluídas uma única vez. A codificação JSON aumenta o tamanho dos dados de imagem em cerca de **33%**.

A restauração substitui os registros atuais. Backups com imagens restauram seus dados originais; backups apenas de registros não restauram imagens. Backups antigos continuam legíveis, mas seu histórico de conversa é ignorado. Grandes coleções de imagens podem exigir muita memória durante a exportação ou restauração.

**Nenhuma exportação do aplicativo inclui o histórico de conversa.** As mensagens expiram **24 horas** após a criação. Wealthy apaga as expiradas enquanto está em execução e verifica ao iniciar ou voltar ao primeiro plano. Se o iOS suspender ou encerrar o aplicativo, a exclusão ocorre na próxima execução. Mensagens expiradas são excluídas da tela e do contexto da IA.

O OCR de recibos destina-se a **textos em japonês e inglês**. A extração automática de valores destina-se a **ienes japoneses inteiros**; moedas estrangeiras exigem entrada manual. Valores e datas vêm do analisador OCR, não de suposições da IA. Usa-se a data impressa legível; caso contrário, a data do retorno da câmera antes do reconhecimento é usada e marcada para conferência. Uma categoria adequada é reutilizada ou uma nova é criada se necessário. Todos os detalhes extraídos podem ser editados.

Em uma medição no iPhone 16 Pro Max com iOS 27.2 usando as mesmas **15 imagens de desenvolvimento**, os totais JPY coincidiram em **6/10** casos legíveis; os outros quatro ficaram sem confirmação. As datas impressas coincidiram em **14/14**, e as categorias híbridas em **14/14 amostras rotuladas**; a taxa de erro de caracteres das linhas selecionadas permaneceu em **11.22%**. Essas imagens também foram usadas no desenvolvimento: os resultados não são de um conjunto independente nem estimativas de precisão para novos recibos. Consulte o [relatório de medição](Verification/ReceiptImageOCR/RESULTS.md) para os resultados históricos no macOS, exclusões e detalhes. Sempre confira antes de salvar.

## Compilar a partir do código-fonte

Use Xcode com o **SDK do iOS 26 ou posterior**. As compilações de desenvolvimento são verificadas com **Xcode 27.0**. Abra `Wealthy/Wealthy.xcodeproj`, selecione o esquema **Wealthy**, configure sua equipe de assinatura e execute em um iPhone ou iPad compatível. O projeto usa frameworks do sistema Apple sem dependências externas de pacotes Swift.

As verificações em um iPhone 16 Pro Max com iOS 27.2 confirmaram respostas da IA em japonês e inglês, além das operações locais de despesas, carteiras e cartões de pontos e da caixa de diálogo de backup. Outros dispositivos e fluxos de trabalho não testados continuam sem verificação. Consulte as [instruções de verificação](Verification/README.md).

A **pré-versão v0.1.1** contém o código-fonte descrito aqui. Não inclui um aplicativo assinado para download; consulte os limites de verificação antes de compilar.

## Licença

Todos os direitos reservados. A redistribuição do código-fonte ou dos binários exige autorização.
