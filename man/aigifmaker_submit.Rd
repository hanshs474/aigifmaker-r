\name{aigifmaker_submit}
\alias{aigifmaker_submit}
\alias{aigifmaker_status}
\alias{aigifmaker_wait}
\alias{aigifmaker_credits}
\title{Submit a GIF, look it up, wait for it, read your credits}
\usage{
aigifmaker_submit(prompt, api_key = NULL, post = aigifmaker_post)
aigifmaker_status(id, api_key = NULL, post = aigifmaker_post)
aigifmaker_wait(id, api_key = NULL, poll_seconds = 3, timeout_seconds = 900, post = aigifmaker_post)
aigifmaker_credits(api_key = NULL, post = aigifmaker_post)
}
\arguments{
\item{prompt}{What the GIF should show.}
\item{id}{The task id returned by \code{aigifmaker_submit}.}
\item{api_key}{Key from \url{https://aigifmaker.ai/settings/apikeys}; defaults to AIGIFMAKER_API_KEY.}
\item{poll_seconds}{How often the task is polled.}
\item{timeout_seconds}{Deadline for the wait.}
\item{post}{The HTTP function; replaceable in tests.}
}
\value{\code{aigifmaker_submit}: the task id. \code{aigifmaker_status}: a list with \code{id}, \code{status}
("pending", "processing", "success" or "failed"), \code{images} and, while queued, \code{queued}.
\code{aigifmaker_wait}: the GIF URL. \code{aigifmaker_credits}: remaining credits as an integer (free to call).}
\description{Lower-level calls for submitting now and collecting later.}
\examples{
\dontrun{
id <- aigifmaker_submit("happy birthday text bouncing in rainbow letters")
aigifmaker_status(id)$status
aigifmaker_wait(id)
aigifmaker_credits()
}
}
