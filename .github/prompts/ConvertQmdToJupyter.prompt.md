The purpose of this prompt is to provide precise, implementable directions for converting homeworks originally written in Quarto markdown (.qmd) format to Jupyter notebook (.ipynb) format.

## High-level goals

- Produce a runnable Jupyter notebook that preserves the original text, code, images, math, and structure as closely as possible.
- Make notebooks that use R code only (see kernel rules below). Omit per-chunk qmd options from the produced notebook unless the user explicitly requests preservation.

## Instructions

- You will be provided with a Quarto markdown (.qmd) file that contains a homework assignment or activity. This may include prose, R code blocks, images, links, LaTeX math, and citations.
- Convert the .qmd file into a Jupyter notebook (.ipynb) in a way that is loadable by standard Jupyter tools (nbformat >= 4).
- Transfer text, code blocks, images, and links accurately. Preserve layout (headings, lists, blockquotes) in markdown cells.
- For callout blocks (e.g., notes, warnings), convert to markdown a markdown cell highlighted in red with a title corresponding to the callout block. E.g. a "Note" callout becomes a markdown cell with a red background and a title "Note". Ensure that the text is not transparent.
	- Here is an example of a callout block in the Jupyter notbook: <div style="border:2px solid #b71c1c; background-color:#ffebee; padding:1em; border-radius:6px; color:#212121;">
<strong>Important</strong>

When you click the run button for a block, it simply runs the code in the current session. I.e. as you make changes to R's warehouse, the code block you run will reference the current state of the warehouse. When you Run the whole notebook runs from the top it cleans out that warehouse and starts from the top. For this reason, if you run blocks multiple times or out of order, you may get unexpected results when you Run the whole document. Before you submit your documents, <strong>always restart your session and Run All and then double check your answers to make sure that your answers match your explanations.</strong>
</div>s
- For elements without a direct equivalent in notebooks (custom filters, callouts, certain fenced divs), preserve the original source in a clearly labeled "Conversion notes" cell and suggest alternatives.
- Transfer all text as is, preserving formatting (bold, italics, links), unless it references Quarto, in which case, rephrase to remove Quarto-specific mentions (e.g., change "In this Quarto document..." to "In this document...").
- Refer to chunks and cells as blocks.
- Always ask clarifying questions when you are unsure about how to handle specific content or formatting, but ask your questions one at a time.
- Always remove the knitr options.

## Kernel & language selection (R-only policy + user confirmation)

- All converted notebooks must contain R code cells only.
- Before conversion begins, ask the user which kernel to use. The user will typically specify a conda environment that provides an R kernel. Request the kernelspec name (for example, `ir` or the conda environment's kernel name). If the user provides no preference, default to the commonly used R kernel name `ir` but still note this choice in the notebook's top cell.
- After the user confirms the kernel, set `metadata.kernelspec` and `metadata.language_info` accordingly in the notebook metadata.

## Frontmatter handling, title cell, and instructions cell

- Convert the top YAML frontmatter into a title markdown cell. Create the first cell with a rendered title (e.g., `# <title>`) and include common metadata fields (author) as a short bullet list beneath the title. For all activities ensure there is a space for the for a Coder, Developer, and a Communicator to write their names instead of author.
- Don't include a date field even if it's in the qmd file.
- If the YAML contains additional fields that may be relevant, include the full raw YAML in a separate markdown cell titled "Original frontmatter (raw)" so nothing is lost.
- Under the title cell add the following a markdown cell with the following text:

	```
	- Make a duplicate copy of this project in your own Deepnote workspace and share it with your teammates.

	- To submit this Activity, click the **Share** button in the top right hand corner of the screen, select "Edit" under "Anyone with a link to this project", and then copy the link into the corresponding Canvas assignment. Remember that only the **Coder** role should submit the assignment in Canvas.
	```

## Chunk options

- Do not carry QMD per-chunk options (e.g., `eval`, `echo`, `results`) into the notebook by default. qmd chunkoptions can be omitted from the produced notebook.
- If a chunk has `eval: false` and the user specifically requests preservation, add a leading comment (`# eval: false`) at the top of the corresponding code cell and add a brief note to "Conversion notes"; otherwise drop the chunk option.

## Images and attachments

- Preserve relative image links. If an `--embed` flag is requested, embed images as notebook attachments (base64) and update the image references.
- If not embedding, add a top-level "Required files" note listing any external assets the notebook depends on.

## Math, citations, and bibliography

- Preserve inline ($...$) and display ($$...$$) math as-is in markdown cells.
- Convert citations to readable placeholders (e.g., `[@smith2020] -> (Citation: smith2020)`) and add a note in the top "Conversion notes" cell pointing to the original bibliography path.

## Exercise conversion pattern (R-only)

- For every Exercise block in the QMD, convert using this template:
	1. Markdown cell: exercise header and instructions (include original text). (metadata.language: "markdown")
 2. If the exercise requires code: a code cell immediately after with the first line containing `# Insert code here` and `metadata.language` set to "r". Do not include qmd chunk options unless the user asked for them.
 3. If the exercise requires a written answer: add a markdown cell with `Insert interpretation here`.
- For multipart exercises, repeat the pattern for each subpart.
4. If a code cell is used to as an example do not add the `# Insert code here` line. If you are unsure if a code cell is an example or part of an exercise, ask the user what to do.

## Cell metadata rules

- Each cell must include `metadata.language` indicating the cell's language ("markdown" or "r").
- For existing notebooks being edited, preserve `metadata.id`. For generated notebooks, include stable UUIDs for `metadata.id` where possible (implementers can generate these programmatically).

## Execution policy

- Add an optional `execute: true|false` flag to the conversion process (default: false). If `execute: true`, run the notebook with nbclient/nbconvert using the confirmed R kernel, capture outputs, and embed them in the notebook. If execution fails, collect the error output and attach it to the "Conversion notes" cell.

## Validation & acceptance criteria

- The converter must run nbformat.validate() on the produced notebook. Report pass/fail.
- Acceptance checklist (must be reported after conversion):
	- Notebook opens in Jupyter without JSON errors.
	- All top-level R code blocks from the QMD appear as code cells with `metadata.language` set to "r".
	- All Exercise headers are present and followed by the required placeholder cells.
	- Images referenced exist or are embedded; otherwise they are listed in "Required files".
	- YAML frontmatter has been converted into a title cell (and raw YAML is included if required).

## Conversion notes policy

- Any content that cannot be converted automatically must be captured in a top-level markdown cell titled "Conversion notes". For each item include: the original snippet, why it could not be converted, and a suggested manual fix.

## Example (tiny QMD -> expected notebook snippet)

- QMD sample:

	```
	---
	title: HW 1
	author: Eric
	---

	## Exercise 1

	Write R code to compute mean of x.

	```{r}
	mean(x)
	```
	```

- Expected notebook cells (conceptual):
	- Cell 1 (markdown): Title cell generated from YAML: `# HW 1` with a short bullet list including Coder, Develop, and Communicator.
	- Cell 2 (markdown): "## Exercise 1" + instruction text. (metadata.language: "markdown")
	- Cell 3 (code, language: "r"): first line `# Insert code here` then `mean(x)`; do not include qmd chunk options by default.

## Output

- The instructions for every Exercise should be represented as described in the "Exercise conversion pattern" section: a markdown cell for instructions, a code cell with `Insert code here` if coding is required, and a markdown cell with `Insert interpretation here` if a written answer is required.

- After conversion, produce a short report listing which acceptance criteria passed and any items placed in "Conversion notes".

---
If you want, I can apply this updated prompt file directly (it is applied already if you asked) and optionally convert a sample `.qmd` from this repo to a notebook using the new rules; tell me which `.qmd` to convert and the kernelspec name to use (or I will use `ir` by default).