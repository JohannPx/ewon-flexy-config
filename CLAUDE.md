# CLAUDE.md - Configuration Claude Code

## Commandes autorisées

Les opérations suivantes sont pré-approuvées et ne nécessitent pas de confirmation :

```
# Git
git status
git diff
git log
git add
git commit
git push
git branch
git checkout
git pull
git fetch
git stash

# Build
dotnet build
dotnet publish
dotnet restore
powershell -Sta -Command
powershell -Command
```

## Architecture du projet

- **PowerShell WPF** : Application principale (9 modules + entry point) — wizard 8 étapes, multilingue FR/EN/ES/IT
- **C# .NET 8 wrapper** (`wrapper/`) : Exe auto-installable avec auto-update GitHub Releases
- **CI/CD** : GitHub Actions — 3 jobs (build .ps1 → package .exe → release)

## Conventions

### Commits
Format : `type: description en français`
Types : `feat`, `fix`, `docs`, `refactor`, `ci`, `test`

### Branches
- `main` : production (releases stables versionnées `vX.Y.Z`)
- `dev` : développement (pre-releases `vX.Y.Z-dev.N`)

### Version
Source de vérité : `manifest.json` champ `version`

## Fichiers clés

| Fichier | Rôle |
|---------|------|
| `scripts/Prepare_Ewon_SD.ps1` | Entry point PowerShell |
| `scripts/modules/*.ps1` | 9 modules (AppState, Localization, Validation, Config, Network, Firmware, Generator, UIHelpers, UI) |
| `wrapper/Program.cs` | Wrapper C# (install, update, launch) |
| `wrapper/EwonFlexySdPrep.csproj` | Projet .NET 8 |
| `scripts/GenerateIcon.ps1` | Génération icône .ico pour le build |
| `.github/workflows/build-release.yml` | Pipeline CI/CD |
| `manifest.json` | Version et métadonnées |
