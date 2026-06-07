# How the Ocsigen Start documentation is generated

The Ocsigen Start documentation published at <https://ocsigen.org/ocsigen-start/>
is built with **odoc** and themed with the Ocsigen site chrome by
[**wodoc**](https://github.com/ocsigen/wodoc) (an odoc driver).

Ocsigen Start is a **client/server** project: it ships its server and client APIs
as two libraries of the same package (`ocsigen-start.server` /
`ocsigen-start.client`) with the **same module names**, so `dune build @doc`
collides. The API is therefore built with `odoc_driver ocsigen-start --remap` on
the **installed** package — the documented version is whatever the build switch
has installed.

## Sources

| What | Where | Format |
|---|---|---|
| Manual | the package's `(documentation)` `.mld` (built with the API) | odoc pages |
| Manual nav order | `doc/manual/menu.wiki` (overlaid from the `wikidoc` branch by CI) | wiki menu |
| Server / client API | `doc/server.indexdoc` / `doc/client.indexdoc` | odoc index |
| Site configuration | [`doc/wodoc`](wodoc) | wodoc config (S-expression) |

The whole site — per-side API navs, the client/server switch, the body colour,
the shared manual nav and the relative cross-links into sibling Ocsigen projects
— is declared in [`doc/wodoc`](wodoc) and produced by a single `wodoc build`.
There is **no `build.sh`** and no Python.

## Build

```
opam install . --with-doc        # the version to document (installed)
opam install wodoc
git show origin/wikidoc:doc/dev/manual/menu.wiki > doc/manual/menu.wiki
wodoc build --config doc/wodoc --label dev --out _doc-site/dev \
  --menu https://ocsigen.org/wodoc/menu.html
```

> **Prerequisite (CI).** The cross-library links need the `odoc_driver`
> `base_args` fix, not yet upstreamed; CI must pin `odoc` / `odoc-driver` from the
> patched source until it lands (see the workflow comments).

## Deployment (CI)

[`.github/workflows/doc.yml`](../.github/workflows/doc.yml) deploys to **`gh-pages`**
(served at `ocsigen.org/ocsigen-start/`). The CI triggers **only on `master`**:

- **push to `master`** → rebuilds and deploys the **`dev`** docs only.

Stable versions are built by hand and committed to `gh-pages` (with `latest`
repointed) at release time. Each CI run replaces only the `dev/` directory.
