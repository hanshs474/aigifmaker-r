# aigifmaker

Turn text into animated GIFs with AI GIF Maker. Native GIF generation — no video conversion. Type what you want and download your GIF in about a minute.

This is the official R package for [AI GIF Maker](https://aigifmaker.ai/?utm_source=r-universe&utm_medium=package). One call sends your prompt, waits for the GIF and returns its URL.

```r
library(aigifmaker)

url <- aigifmaker_generate("a corgi in sunglasses dancing on a beach, looping")
url  # the finished GIF
```

## Install

```r
install.packages("aigifmaker", repos = c("https://hanshs474.r-universe.dev", "https://cloud.r-project.org"))
```

Imports `curl` and `jsonlite`.

## API key

Create a key at https://aigifmaker.ai/settings/apikeys, then pass it as `api_key =` or set it:

```r
Sys.setenv(AIGIFMAKER_API_KEY = "sk-...")
```

Each GIF costs 1 credit on your AI GIF Maker account, the same as on the website. New accounts get one free GIF (it carries a small aigifmaker.ai badge). A GIF that fails to generate gives its credit back. Credit packs are on the [pricing](https://aigifmaker.ai/pricing?utm_source=r-universe&utm_medium=package) page.

```r
aigifmaker_credits()  # remaining credits, free to call
```

## Submit now, collect later

```r
id <- aigifmaker_submit("happy birthday text bouncing in rainbow letters")
aigifmaker_status(id)$status   # pending | processing | success | failed
url <- aigifmaker_wait(id)     # polls every 3 seconds
```

A run from an account that has not bought credits yet may wait in a short queue first (`queued` is `TRUE` while `status` stays `processing`). That is normal; `aigifmaker_generate()` and `aigifmaker_wait()` keep polling, for up to 15 minutes by default (`timeout_seconds`).

## Errors worth catching

Each failure is a condition you can catch by class:

- `aigifmaker_auth`: no key, or the key is wrong or deleted
- `aigifmaker_quota`: the account is out of credits
- `aigifmaker_rejected`: the content filter refused the prompt, or a cooldown is active; reword it
- `aigifmaker_failed`: the run was accepted but failed; the message says why
- `aigifmaker_timeout`: the wait ran out; the GIF may still finish in your history

Anything else is `aigifmaker_other` with the server's message. All of them inherit `aigifmaker_error`.

```r
tryCatch(aigifmaker_generate("a tiny dragon sneezing glitter"),
         aigifmaker_quota = function(e) message("top up first"))
```

## Tests

```bash
R CMD build . && R CMD check aigifmaker_0.1.0.tar.gz   # mocked, offline
AIGIFMAKER_SMOKE=1 Rscript tests/run.R                   # plus two free live checks, no generation
```

MIT licensed. Questions: support@aigifmaker.ai
