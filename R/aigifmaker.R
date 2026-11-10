aigifmaker_base <- function() getOption("aigifmaker.base_url", "https://aigifmaker.ai")
aigifmaker_keys_url <- "https://aigifmaker.ai/settings/apikeys"
aigifmaker_pricing_url <- "https://aigifmaker.ai/pricing"

# Every failure carries a class to branch on: aigifmaker_auth, aigifmaker_quota,
# aigifmaker_rejected, aigifmaker_failed, aigifmaker_timeout, aigifmaker_other.
aigifmaker_stop <- function(kind, msg, code = NA_integer_) {
  stop(structure(class = c(paste0("aigifmaker_", kind), "aigifmaker_error", "error", "condition"),
                 list(message = paste("aigifmaker:", msg), call = NULL, code = code)))
}

# Map a refusal (JSON code other than 0) to the kind that says what to do next.
aigifmaker_classify <- function(code, message) {
  low <- tolower(message)
  if (grepl("invalid api key", low, fixed = TRUE) || grepl("no auth", low, fixed = TRUE)) return("auth")
  if (grepl("insufficient credits", low, fixed = TRUE)) return("quota")
  if (is.numeric(code) && !(code %in% c(0, -1))) return("rejected")
  "other"
}

# POST a JSON body; returns the decoded answer. Replaceable in tests via `post =`.
aigifmaker_post <- function(path, body, key) {
  h <- new_handle()
  headers <- list("Content-Type" = "application/json", "User-Agent" = "aigifmaker-r/0.1.0")
  # Without a key the request still goes out: the service answers with a wall, which becomes aigifmaker_auth.
  if (nzchar(key)) headers$Authorization <- paste("Bearer", key)
  do.call(handle_setheaders, c(list(h), headers))
  json <- if (length(body)) toJSON(body, auto_unbox = TRUE) else "{}"
  handle_setopt(h, timeout = 60, postfields = json)
  res <- curl_fetch_memory(paste0(aigifmaker_base(), path), handle = h)
  tryCatch(fromJSON(rawToChar(res$content), simplifyVector = FALSE), error = function(e) NULL)
}

aigifmaker_key <- function(api_key) {
  key <- if (!is.null(api_key)) api_key else Sys.getenv("AIGIFMAKER_API_KEY")
  trimws(key)
}

# Every answer is HTTP 200; the JSON code tells success from refusal.
aigifmaker_call <- function(path, body, api_key, post) {
  env <- post(path, body, aigifmaker_key(api_key))
  if (!is.list(env) || !is.numeric(env$code)) aigifmaker_stop("other", "unexpected answer from the service")
  if (env$code != 0) {
    msg <- if (is.null(env$message)) "request refused" else as.character(env$message)
    kind <- aigifmaker_classify(env$code, msg)
    if (kind == "quota") msg <- paste0(msg, "; top up at ", aigifmaker_pricing_url)
    aigifmaker_stop(kind, msg, as.integer(env$code))
  }
  data <- if (is.list(env$data)) env$data else list()
  if (isTRUE(data$wall)) {
    aigifmaker_stop("auth", paste0("an API key is required; create one at ", aigifmaker_keys_url,
                                   " and set AIGIFMAKER_API_KEY"), 0L)
  }
  data
}

#' @export
aigifmaker_submit <- function(prompt, api_key = NULL, post = aigifmaker_post) {
  if (!is.character(prompt) || !nzchar(trimws(prompt))) aigifmaker_stop("other", "prompt is required")
  d <- aigifmaker_call("/api/ai/generate",
                       list(provider = "openlux", mediaType = "image", model = "gif-maker-v1",
                            scene = "text-to-image", prompt = prompt,
                            options = list(output_format = "gif")),
                       api_key, post)
  if (is.null(d$id)) aigifmaker_stop("other", "the service returned no task id")
  as.character(d$id)
}

#' @export
aigifmaker_status <- function(id, api_key = NULL, post = aigifmaker_post) {
  aigifmaker_call("/api/ai/query", list(taskId = id), api_key, post)
}

#' @export
aigifmaker_credits <- function(api_key = NULL, post = aigifmaker_post) {
  d <- aigifmaker_call("/api/user/get-user-credits", list(), api_key, post)
  as.integer(if (is.null(d$remainingCredits)) 0L else d$remainingCredits)
}

#' @export
aigifmaker_wait <- function(id, api_key = NULL, poll_seconds = 3, timeout_seconds = 900,
                            post = aigifmaker_post) {
  deadline <- Sys.time() + timeout_seconds
  repeat {
    d <- tryCatch(aigifmaker_status(id, api_key, post),
                  aigifmaker_other = function(e) NULL, # a dropped poll is not a failed GIF
                  error = function(e) if (inherits(e, "aigifmaker_error")) stop(e) else NULL)
    if (!is.null(d)) {
      if (identical(d$status, "success") && length(d$images)) return(as.character(d$images[[1]]))
      if (isTRUE(d$status %in% c("failed", "canceled"))) {
        msg <- if (is.null(d$errorMessage)) paste("the GIF", d$status) else d$errorMessage
        aigifmaker_stop(if (identical(d$failureKind, "moderation")) "rejected" else "failed", msg)
      }
    }
    if (Sys.time() + poll_seconds >= deadline) break
    Sys.sleep(poll_seconds)
  }
  aigifmaker_stop("timeout", paste("still running; task", id, "may finish later in your AI GIF Maker history"))
}

#' @export
aigifmaker_generate <- function(prompt, api_key = NULL, poll_seconds = 3, timeout_seconds = 900,
                                post = aigifmaker_post) {
  id <- aigifmaker_submit(prompt, api_key, post)
  aigifmaker_wait(id, api_key, poll_seconds, timeout_seconds, post)
}
