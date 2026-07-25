# Website Quiz

## Overview

Part of the top-of-funnel engagement, this multiple-choice quiz is design to help potential clients:
1. self-check for symptoms (as prompted by the quiz)
2. understand how their symptoms map to services offered by Andrea's business.

The quiz must be formatted in a similar manner to the rest of the website design.

## Flow

* On the main page, visitors will be directed to the quiz with a link "Is HRT right for me?"
* The quiz will prompt visitors to chose an answer for a series of questions (see the "Content" section below).
* Based on their cumulative "score", the quiz will show the visitor a final screen with result explanation text plus call to action text to proceed further into the client onboarding funnel. The call to action will also include the button to start the booking process.
* A very clear disclaimer will always be displayed on the final screen: "This quiz is for informational purposes only and does not replace medical advice. Final treatment decisions are made after a full clinical assessment."

## Technical design
* The quiz content and flow will go through a few iterations. When architecting the quiz code, expect to have several modifications
* The quiz will use the same modal definition as the booking process: pop into a modal for desktop users, and in a new tab for mobile users (where mobile users are defined as anyone with a viewportal width less than 768px).
* Each quiz question is presented alone.
* Each quiz question will be formatted as follows:
    * Header. At the top of each question screen. For markdown-formatted questions, this will be signified with a single `#`.
    * Clarification / expansion text. Between the header and the answer options. It should be formatted to be slightly smaller than the header, and may be formatted with an ordered or unordered list
    * Answer options. Presented at the bottom of each question screen. These are the answers from which the visitor can select, and will be presented as either "single choice" (radio buttons) or "multiple choice" (checkboxes). In the case of "multiple choice" it will be possible that the visitor not select any options. The selection control should be placed left of the option text.
* Depending on which answer the visitor chooses, the visitor will accumulate points in either the `preferred` or `nonpreferred` scoring buckets.
* The quiz results will be based on the score. If the visitor has  _any_ points in the `nonpreferred` bucket, the visitor will see the `nonpreferred` result option. Otherwise the visitor will see the `preferred` result option.

### Schema
* `questions` contains the collection of individual question definition nodes. It is defined in the order it should be presented to the visitor - DO NOT change the ordering
    * `text` contains the words that are being "asked" to the visitor. If the text starts with a `|` then the text is defined with some markdown formatting
    * `type` controls the UX of the question. If type is `single` then it's a radio-button UX where only one answer is possible and an answer MUST be selected before proceeding to the next question, `multiple` is a checkbox UX where mulitple answer selections is possible and an answer MAY be selected before proceeding to the next question
    * `answer` contains the collection of individual answer option nodes. It is defined in the order it should be presented to the visitor - DO NOT change the ordering
        * `text` contains the words of a single answer option
        * `none` is a flag used to indicate the circumstance in which the visitor has selected no options.
        * `score` contains the name of the scoring bucket, either `preferred` or `nonpreferred`
* `results` contains the collection of individual result definition nodes.
    * `bucket` the name of the result bucket, either `preferred` or `nonpreferred`.
    * `text` contains the result explanation text
    * `call_to_action` contains the text that encourages the visitor to continue their onboarding journey by starting the appointment booking process

## Content
* Specified in YAML format
* DO NOT change the sorting of questions - they are presented in this list in the same way they should be presented to visitors
* Content lives in @site/data/quiz.yaml
