import CoolProp.CoolProp as CP
from rich.console import Console

console = Console()

def main():
    console.print(f"[bold green]CoolProp Version:[/bold green] {CP.get_global_param_string('version')}")

    temp_k = CP.PropsSI('T', 'P', 101325, 'Q', 0, 'Water')

    console.print(f"[bold blue]Boiling point of water at 1 atm:[/bold blue] {temp_k:.2f} K")

if __name__ == "__main__":
    main()
