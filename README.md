# minecraft-server

Servidor de Minecraft rodando em um container Docker.

## Como jogar

### CurseForge

1. Acesse o CurseForge e baixe o modpack [`HazardousDaniel's Unlimited`](https://www.curseforge.com/minecraft/modpacks/hazardousdaniels-unlimited).
2. Jogue, simples assim :happy:.

---

### Tlauncher

1. Acesse o site TLMods e baixe o modpack [`HazardousDaniel's Unlimited`](https://tlmods.org/en/modpacks/hazardousdaniels-unlimited/). Isso vai sincronizar com o launcher do TLauncher.
2. É preciso baixar mais dois mods que não estão inclusos pelo TLMods, baixe aqui:
    - [Artifacts](https://www.curseforge.com/minecraft/mc-mods/artifacts/files/5384768) (versão 5.0.6) - *requerido*
    - [Harvest with ease](https://www.curseforge.com/minecraft/mc-mods/harvest-with-ease/download/5384545) (versão 9.0.0.3-beta) - *opcional*
3. Mova os mods baixados para a pasta `mods` do seu jogo.
    - Na pasta do jogo, `versions/HazardousDaniel's Unlimited Unlimited--1.2.1/mods`
4. Jogue.

## Como rodar o servidor

1. Clone o repositório.
2. Acesse o [CurseForge Studios](https://console.curseforge.com/#/api-keys) para obter uma API key e adicione-a ao arquivo `.env`. Mude o `RCON_PASSWORD` para uma senha segura.
3. Execute o comando `docker compose up -d` na raiz do projeto.
4. O servidor estará disponível na porta `25565`.
