import os
import sys
import json
from gumloop import GumloopClient

def generate_questions():
    """
    Generates questions using the Gumloop Python SDK.
    Takes a topic as a command-line argument.
    Returns the transformed list of questions in the format expected by the Go backend.
    """
    # Load environment variables from .env file

    if len(sys.argv) < 2:
        print(json.dumps({"error": "Topic argument is missing"}), file=sys.stderr)
        sys.exit(1)

    topic = sys.argv[1]
    
    api_key = os.getenv("GUMELOOP_API_KEY")
    user_id = os.getenv("GUMELOOP_USER_ID")
    saved_item_id = os.getenv("GUMELOOP_FLOW_ID")
    if not api_key:
        print(json.dumps({"error": "GUMELOOP_API_KEY not found in .env file"}), file=sys.stderr)
        sys.exit(1)
    if not user_id:
        print(json.dumps({"error": "GUMELOOP_USER_ID not found in .env file"}), file=sys.stderr)
        sys.exit(1)

    try:
        client = GumloopClient(api_key=api_key, user_id=user_id)
        
        # Temporarily redirect stdout to suppress Gumloop client's verbose output
        import io
        old_stdout = sys.stdout
        sys.stdout = io.StringIO()
        
        try:
            gumloop_response = client.run_flow(
                flow_id=saved_item_id,
                inputs={"topic": topic}
            )
        finally:
            sys.stdout = old_stdout # Restore stdout
        
        # Extract the questions list. It should contain one string.
        questions_list = gumloop_response.get("questions", [])
        if not questions_list or not isinstance(questions_list, list) or len(questions_list) == 0:
            print(json.dumps({"error": "'questions' key not found, not a list, or empty in Gumloop response"}), file=sys.stderr)
            sys.exit(1)

        # Get the first (and presumably only) string from the list
        questions_json_string = questions_list[0]

        # Remove markdown code block fences if present
        if questions_json_string.startswith('```json\n') and questions_json_string.endswith('\n```'):
            questions_json_string = questions_json_string[len('```json\n'):-len('\n```')]

        raw_questions = json.loads(questions_json_string)

        # Transform questions to the desired Go format
        transformed_questions = []
        for i, q in enumerate(raw_questions):
            options_list = []
            correct_answer_text = ""
            
            # Convert options from object to list and find the correct answer text
            # Assuming options are always A, B, C, D and in order
            option_keys = ["A", "B", "C", "D"]
            for key in option_keys:
                if key in q["options"]:
                    options_list.append(q["options"][key])
                    if q["correct_answer"] == key:
                        correct_answer_text = q["options"][key]

            transformed_questions.append({
                "id": str(i + 1), # Assign a simple ID
                "text": q["question"],
                "options": options_list,
                "answer": correct_answer_text
            })
        
        # Print the transformed questions as a JSON array
        print(json.dumps(transformed_questions))

    except Exception as err:
        print(json.dumps({"error": f"Error using Gumloop SDK: {err}"}), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    generate_questions()