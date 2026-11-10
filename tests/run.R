library(aigifmaker)
queue <- list(); calls <- list()
fake <- function(path, body, key) {
  calls[[length(calls) + 1]] <<- list(path = path, body = body, key = key)
  r <- queue[[1]]; queue <<- queue[-1]; r
}
ok <- function(d) list(code = 0L, message = "ok", data = d)
submitted <- ok(list(id = "task_1", status = "pending", taskId = "up_9", provider = "openlux"))

queue <- list(submitted,
              ok(list(id = "task_1", status = "processing", images = list(), queued = TRUE, queueEta = 40L)),
              ok(list(id = "task_1", status = "success", images = list("https://cdn.aigifmaker.ai/g/task_1.gif"), watermarked = list(TRUE))))
url <- aigifmaker_generate("a corgi dancing", api_key = "sk-x", poll_seconds = 0, post = fake)
b <- calls[[1]]$body
stopifnot(url == "https://cdn.aigifmaker.ai/g/task_1.gif", calls[[1]]$path == "/api/ai/generate", calls[[1]]$key == "sk-x",
          b$provider == "openlux", b$mediaType == "image", b$model == "gif-maker-v1", b$scene == "text-to-image",
          b$prompt == "a corgi dancing", b$options$output_format == "gif",
          calls[[2]]$path == "/api/ai/query", calls[[2]]$body$taskId == "task_1")

queue <- list(ok(list(remainingCredits = 42L, made = 3L)))
stopifnot(aigifmaker_credits(api_key = "sk-x", post = fake) == 42L)

queue <- list(submitted, ok(list(id = "task_1", status = "failed", errorMessage = "upstream error", refundNote = "credit returned")))
e <- tryCatch(aigifmaker_generate("x", api_key = "sk-x", poll_seconds = 0, post = fake), aigifmaker_error = function(e) e)
stopifnot(inherits(e, "aigifmaker_failed"), grepl("upstream error", conditionMessage(e)))
queue <- list(submitted, ok(list(id = "task_1", status = "failed", errorMessage = "blocked", failureKind = "moderation")))
e <- tryCatch(aigifmaker_generate("x", api_key = "sk-x", poll_seconds = 0, post = fake), aigifmaker_error = function(e) e)
stopifnot(inherits(e, "aigifmaker_rejected"))

cases <- list(list(list(code = -1L, message = "invalid API key — create one at https://aigifmaker.ai/settings/apikeys"), "auth"),
              list(list(code = -1L, message = "no auth, please sign in"), "auth"),
              list(ok(list(wall = TRUE, reason = "anon_credits")), "auth"),
              list(list(code = -1L, message = "insufficient credits"), "quota"),
              list(list(code = -2L, message = "content cooldown"), "rejected"),
              list(list(code = -1L, message = "upstream busy"), "other"))
for (c in cases) {
  queue <- list(c[[1]])
  e <- tryCatch(aigifmaker_submit("x", api_key = "sk-x", post = fake), aigifmaker_error = function(e) e)
  stopifnot(inherits(e, paste0("aigifmaker_", c[[2]])))
}

if (nzchar(Sys.getenv("AIGIFMAKER_SMOKE"))) {
  e <- tryCatch(aigifmaker_credits(api_key = "sk-invalidtest000"), aigifmaker_error = function(e) e)
  stopifnot(inherits(e, "aigifmaker_auth"))
  e <- tryCatch(aigifmaker_submit("a cat waving", api_key = ""), aigifmaker_error = function(e) e)
  stopifnot(inherits(e, "aigifmaker_auth"))
  cat("live ok: wrong key -> aigifmaker_auth, no key -> aigifmaker_auth (wall)\n")
}
cat("all tests passed\n")
