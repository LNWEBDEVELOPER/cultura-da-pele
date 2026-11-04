# Configuração do acesso ao estúdio

## O que o fluxo faz

- O artista solicita acesso com e-mail e senha. O Supabase guarda a senha; ela nunca é encaminhada por e-mail.
- O artista confirma o endereço pelo e-mail de autenticação.
- O proprietário recebe um aviso de novo pedido, entra na área do estúdio e aprova ou recusa.
- Somente contas aprovadas podem publicar trabalhos e imagens. A galeria é compartilhada para todos os visitantes.

## Configuração inicial

1. Projeto criado: Art of Tatto (`tfftyjxvcqwicxnzjpng`, região São Paulo).
2. Abra **SQL Editor** e execute `supabase/schema.sql`.
3. Publique o site no GitHub Pages e acrescente a URL em **Authentication → URL Configuration → Redirect URLs**. Ative confirmação de e-mail.
4. Registre a conta do proprietário usando a área **Área do estúdio** no próprio site e confirme o e-mail.
5. No SQL Editor, promova essa conta. Troque o e-mail pelo seu:

   ```sql
   update public.profiles
   set role='owner', approval_status='approved'
   where email=lower('lnwebdeveloperads@gmail.com');
   ```

6. A URL e a chave publicável do projeto já estão configuradas em `dist/index.html`. A chave `sb_publishable_...` é destinada ao navegador; as políticas RLS protegem os dados. Nunca coloque uma chave secreta no HTML.
7. Configure um domínio remetente verificado no Resend. Publique a função:

   ```sh
   supabase functions deploy notify-owner
   supabase secrets set OWNER_EMAIL=lnwebdeveloperads@gmail.com NOTIFICATION_FROM_EMAIL="Cultura da Pele <avisos@seu-dominio.com>" RESEND_API_KEY=re_... SITE_URL=https://lnwebdeveloper.github.io/cultura-da-pele/
   ```

   A função usa `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` do ambiente de funções Supabase. A função exige sessão autenticada e e-mail já confirmado. O aviso segue para o proprietário uma vez por pedido pendente; a senha nunca sai do Supabase Auth.
8. Publique a pasta `dist` no GitHub Pages. O ZIP da entrega inclui os arquivos publicados e a pasta `supabase` com o schema e a função.

## Observações

- Os três estudos visuais atuais são incluídos como exemplos no schema.
- O primeiro cadastro proprietário deve ser promovido manualmente no SQL; depois disso, as aprovações ocorrem na própria página.
- Configure SMTP próprio em **Authentication → SMTP Settings** para que os e-mails de confirmação cheguem de forma confiável.


