# Cultura da Pele — configuração do estúdio

## O que já está configurado

- Organização Supabase: **Art of Tatto**.
- Projeto: **Art of Tatto**, em São Paulo (`tfftyjxvcqwicxnzjpng`).
- Banco: schema e políticas de acesso aplicados; tabelas `profiles` e `tattoos` aparecem no Table Editor.
- Site: publicado em https://lnwebdeveloper.github.io/cultura-da-pele/ e conectado ao projeto.
- Confirmação de e-mail e URL de redirecionamento estão ativadas.
- Função `notify-owner` publicada; os secrets `OWNER_EMAIL` e `SITE_URL` já estão configurados.
- A organização antiga **Martins Barbearia** foi renomeada para **lnwebdeveloper**.

## Próximos passos para o proprietário

1. No site, abra **Área do estúdio**, cadastre `lnwebdeveloperads@gmail.com` com uma senha e confirme o e-mail. A senha fica no Supabase Auth e nunca é enviada por e-mail.
2. Depois da confirmação, execute uma vez no SQL Editor para promover essa conta:

   ```sql
   update public.profiles
   set role='owner', approval_status='approved'
   where email=lower('lnwebdeveloperads@gmail.com');
   ```

3. Para habilitar os avisos automáticos dos novos pedidos, verifique um domínio remetente no Resend e adicione `RESEND_API_KEY` e `NOTIFICATION_FROM_EMAIL` em **Edge Functions → Secrets**. Não coloque a chave no GitHub. Os secrets passam a valer sem novo deploy.
4. Para que os e-mails de confirmação de cadastro cheguem com confiabilidade, configure SMTP próprio em **Authentication → Emails**.

## Como funciona

- O visitante clica em **Tenho interesse** para abrir o orçamento com aquela tatuagem como referência.
- O artista pode pedir acesso com e-mail e senha. Depois de confirmar o e-mail e receber aprovação, consegue adicionar trabalhos à galeria.
- O proprietário aprova ou recusa pedidos pela área do estúdio.
- A galeria atual inclui três estudos visuais conceituais como exemplos.

## Arquivos

- `dist/index.html`: site publicado, conectado à chave publicável do Supabase.
- `supabase/schema.sql`: tabelas, políticas RLS, bucket de imagens e exemplos iniciais.
- `supabase/functions/notify-owner/index.ts`: aviso de novos pedidos ao proprietário.

A chave publicável pode aparecer no navegador. Chaves secretas do Supabase e do Resend devem permanecer nos secrets do projeto, nunca no HTML ou no GitHub.

