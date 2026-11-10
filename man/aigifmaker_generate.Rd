\name{aigifmaker_generate}
\alias{aigifmaker_generate}
\title{Turn a prompt into an animated GIF with AI GIF Maker}
\usage{
aigifmaker_generate(prompt, api_key = NULL, poll_seconds = 3, timeout_seconds = 900,
  post = aigifmaker_post)
}
\arguments{
\item{prompt}{What the GIF should show.}
\item{api_key}{Key from \url{https://aigifmaker.ai/settings/apikeys}; defaults to the AIGIFMAKER_API_KEY environment variable.}
\item{poll_seconds}{How often the task is polled.}
\item{timeout_seconds}{Deadline for the whole call.}
\item{post}{The HTTP function; replaceable in tests.}
}
\value{The URL of the finished GIF.}
\description{Submits one GIF on AI GIF Maker (\url{https://aigifmaker.ai}), waits for it and returns its URL.
Each GIF costs 1 credit on your AI GIF Maker account, the same as on the website.
Failures signal a condition of class \code{aigifmaker_auth}, \code{aigifmaker_quota},
\code{aigifmaker_rejected}, \code{aigifmaker_failed}, \code{aigifmaker_timeout} or \code{aigifmaker_other}.}
\examples{
\dontrun{
aigifmaker_generate("a corgi in sunglasses dancing on a beach, looping")
}
}
