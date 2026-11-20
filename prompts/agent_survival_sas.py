"""
Usage:
------
Run this file with the following command in the terminal:

    inspect [python_file_name] --model [model_name] --epochs 10 --max-samples 1

Where:
    [python_file_name] : name of the Python file containing this task/eval
                          (e.g., eval_task.py)
    [model_name]        : name of the model to evaluate, in the format
                          provider/org/model
                          (e.g., openrouter/anthropic/claude-sonnet-5)
    --epochs 10          : number of times to repeat the evaluation
                          (10 in this example)
    --max-samples 1      : maximum number of samples processed at once
                          (1 in this example)

Example:
    inspect eval_task.py --model openrouter/anthropic/claude-sonnet-5 --epochs 10 --max-samples 1
"""

from inspect_ai import Task, task
from inspect_ai.agent import react
from inspect_ai.dataset import Sample
from inspect_ai.tool import tool
from inspect_ai.model import GenerateConfig 
from inspect_ai.util import sandbox, sandbox_with


@tool
def write_file():
    async def execute(path: str, content: str) -> str:
        """Write (create or overwrite) a file in the sandbox.

        Args:
            path: File path to write to.
            content: Full content to write into the file.

        Returns:
            Confirmation message that the file was written.
        """
        await sandbox().write_file(path, content)
        return f"File written: {path} ({len(content)} chars)"

    return execute


@tool
def run_powershell():
    async def execute(command: str) -> str:
        """Run a PowerShell command in the sandbox and return the output.
        Always waits up to 1500 seconds for the command to complete.
 
        Args:
            command: PowerShell command to run (e.g. calling run_stata.ps1).
 
        Returns:
            stdout/stderr content along with success/failure status.
        """
        result = await sandbox().exec(
            ["powershell", "-ExecutionPolicy", "Bypass", "-Command", command],
            timeout=1500,
        )
        output = result.stdout or ""
        if result.stderr:
            output += f"\n[STDERR]\n{result.stderr}"
        status = "SUCCESS" if result.success else f"FAILED (exit {result.returncode})"
        return f"[{status}]\n{output}"
 
    return execute
 


@tool
def read_file():
    async def execute(path: str) -> str:
        """Read the content of a text file in the sandbox.

        Args:
            path: File path to read.

        Returns:
            Full file content as text.
        """
        return await sandbox().read_file(path, text=True)

    return execute


@tool
def check_file_exists():
    async def execute(path: str) -> str:
        """Check whether a file exists in the sandbox.

        Args:
            path: File path to check.

        Returns:
            "EXISTS" if the file is present, "NOT_EXISTS" otherwise.
        """
        found = await sandbox_with(path)
        return "EXISTS" if found is not None else "NOT_EXISTS"

    return execute


INSTRUCTIONS = """
You are a biostatistics expert, proficient in SAS (SAS 9.4 TS Level 1M4).
Tools: write_file(path, content), run_powershell(command), read_file(path), check_file_exists(path).

Workflow:
1. write_file(path="analysis.sas", content=<SAS code>).
2. run_powershell(command='.\\run_sas.ps1 -File analysis.sas') to run the sas-file.
   run_sas.ps1 reads and prints the log to its output — normally the log is
   already fully contained there.
3. If the output of run_powershell does NOT contain the log content (empty,
   truncated, or reports "No log file was generated"): use
   read_file(path="analysis.log") or/and read_file(path="analysis.lst") to read the log, lst file directly as a fallback.
4. check_file_exists to confirm the plot was created.
5. If the log has errors or plot does not exist: fix analysis.sas with
   write_file() and repeat steps 2-4 until there are no errors and plot exists.
6. submit() with exactly these 3 parts:
   - The full, final SAS code that ran successfully.
   - All requested numbers, clearly labeled:
   - Name of graphs were created (based on check_file_exists).

Do not infer or fabricate any numbers.
"""



@task
def test_colon_death_survival_sas():
    return Task(
        dataset=[Sample(
            input=(
                "File data.csv has columns:\n"
                "'var0': Row name (numeric).\n"
                "'var1': Patient identifier (numeric).\n"
                "'var2': Study identifier (numeric).\n"
                "'var3': Treatment received (values: \"Obs\", \"Lev\", \"Lev+5FU\") (character).\n"
                "'var4': Sex of the patient: 1 = male, 0 = female (numeric).\n"
                "'var5': Age of the patient (numeric).\n"
                "'var6': Obstruction of colon by tumour: 1 = yes, 0 = no (numeric).\n"
                "'var7': Perforation of colon: 1 = yes, 0 = no (numeric).\n"
                "'var8': Adherence to nearby organs: 1 = yes, 0 = no (numeric).\n"
                "'var9': Number of positive lymph nodes detected (numeric).\n"
                "'var10': Censoring status (values: 0 = censored, 1 = event occurred).\n"
                "'var11': Tumor differentiation: 1 = well, 2 = moderate, 3 = poor (numeric).\n"
                "'var12': Tumor extent: 1 = submucosa, 2 = muscle, 3 = serosa, "
                "4 = contiguous structures (numeric).\n"
                "'var13': Surgical intervention: 0 = short, 1 = long (numeric).\n"
                "'var14': Nodal status: 1 = more than 4 positive lymph nodes, "
                "0 = less than 4 positive lymph nodes (numeric).\n"
                "'var15': Follow-up time in days (numeric).\n"
                "'var16': Event type: 1 = recurrence, 2 = death (numeric).\n\n"
                "Now create a survival analysis to do these tasks:\n"
                "* Import the file.\n"
                "* Filter the data to keep only observations whose event type is death. "
                "This filtering step should be based solely on the event-type variable; "
                "* After filtering, remove any remaining observation with a missing "
                "value in treatment, age, sex, or nodal status. Report the number of "
                "observations removed at this step. Use this same cleaned dataset for "
                "all subsequent tasks in this analysis.\n"
                "* Calculate the median survival time. Report the time in days.\n"
                "* Create a graph of Kaplan-Meier stratified by nodal status.\n"
                "* Use the log-rank test for the treatment variable. Report the p-value.\n"
                "* Use a Cox proportional hazards model to estimate hazard ratios for the "
                "effects of age, sex, treatment, and nodal status. Report the hazard "
                "ratio of nodal status.\n"
                "* Calculate Harrell's concordance index (C-statistic) for the Cox "
                "model. Report the value.\n"
                "* Test the proportional hazards assumption for age, sex, treatment, and "
                "nodal status by examining the correlation between Schoenfeld residuals "
                "and ranked survival time. Report the p-value for nodal status.\n"
                "* Utilizing Cox model, plot survival probability for male patient age of 70, "
                "treatment with Lev+5FU, and more than 4 positive lymph nodes across the follow-up time."
                " Also report the predicted survival probability for this patient at the last observed "
                "follow-up time shown in the plot.\n"
                "* Run an extended Cox model with heaviside functions for nodal status "
                "defined about the time cutpoint of 3 years. "
                "Report the hazard ratio for nodal status during the first 3 years of follow-up.\n"
                "* Fit a parametric Weibull survival model using the same covariates "
                "(age, sex, treatment, nodal status), using the accelerated failure "
                "time (AFT) parameterization. Report the raw coefficient for nodal status."

            ),
            files={
                "data.csv": "data/data.csv",
                "run_sas.ps1": "scripts/run_sas.ps1",
            },
        )],
        solver=react(
            prompt=INSTRUCTIONS,
            tools=[write_file(), run_powershell(), read_file(), check_file_exists()],
        ),
        sandbox="local",
        message_limit=90,      # total messages (user+assistant+tool) in the sample
        turn_limit=30,         # total model generation turns ("think + call a tool")
        time_limit=1000,        # real-time limit (seconds) — catches Stata/SAS hangs
        token_limit="500k",
        config=GenerateConfig(
            max_tool_output=1000000,
            cache_prompt=True,
            reasoning_effort="medium",
            temperature = 0,
            seed=42,
        ),
    )