# Cultura da Pele — configuração do estúdio

## O que já está configurado

- Organização Supabase: **Art of Tatto**.
- Projeto: **Art of Tatto**, em São Paulo (`tfftyjxvcqwicxnzjpng`).
- Banco: schema e políticas de acesso aplicados; tabelas `profiles`, `tattoos` e `appointments` aparecem no Table Editor.
- Site: publicado em https://lnwebdeveloper.github.io/cultura-da-pele/ e conectado ao projeto.
- Confirmação de e-mail e URL de redirecionamento estão ativadas.
- Função `notify-owner` publicada; os secrets `OWNER_EMAIL` e `SITE_URL` já estão configurados.
- A organização antiga **Martins Barbearia** foi renomeada para **lnwebdeveloper**.

## Acesso do proprietário

A conta `luannascimentopsp@gmail.com` já está aprovada como proprietária do projeto. Entre pelo formulário da **Área do estúdio**. A agenda é visível somente para essa conta proprietária; ela armazena nome, contato, horário, duração, situação e observações dos atendimentos.

Para habilitar os avisos automáticos de novos pedidos, verifique um domínio remetente no Resend e adicione `RESEND_API_KEY` e `NOTIFICATION_FROM_EMAIL` em **Edge Functions → Secrets**. Para e-mails de confirmação com mais confiabilidade, configure SMTP próprio em **Authentication → Emails**.

## Como funciona

- O visitante clica em **Tenho interesse** para abrir o orçamento com aquela tatuagem como referência.
- O artista pode pedir acesso com e-mail e senha. Depois de confirmar o e-mail e receber aprovação, consegue adicionar trabalhos à galeria.
- O proprietário aprova ou recusa pedidos pela área do estúdio.
- A galeria atual inclui três estudos visuais conceituais como exemplos.

## Arquivos

- `dist/index.html`: site publicado, conectado à chave publicável do Supabase.
- `supabase/schema.sql`: tabelas, políticas RLS, bucket de imagens, exemplos iniciais e SQL da agenda privada.
- `supabase/appointments.sql`: tabela e políticas RLS da agenda privada.
- `supabase/functions/notify-owner/index.ts`: aviso de novos pedidos ao proprietário.

A chave publicável pode aparecer no navegador. Chaves secretas do Supabase e do Resend devem permanecer nos secrets do projeto, nunca no HTML ou no GitHub.

