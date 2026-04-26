#Setup del pacchetto QuantumSavory in modalità dev
using Pkg

# Usa il repository locale clonato (dev mode)
qs_path = joinpath(@__DIR__, "..", "QuantumSavory.jl")
if isdir(qs_path)
    Pkg.develop(path=qs_path)
    println("Using QuantumSavory.jl from local repository (dev mode)")
else
    # Fallback: installa da registro se non c'è il repo locale
    if !haskey(Pkg.project().dependencies, "QuantumSavory")
        Pkg.add("QuantumSavory")
    end
    println("Using QuantumSavory.jl from package registry")
end

# Installa altre dipendenze necessarie
for pkg in ["QuantumOpticsBase", "Plots", "Statistics"]
    if !haskey(Pkg.project().dependencies, string(pkg))
        Pkg.add(string(pkg))
    end
end

using QuantumSavory
using QuantumOpticsBase
using LinearAlgebra
using Statistics
using Random
using Plots

println("    GROVER'S ALGORITHM - Pattern Search 3x3 Grid")

const N_QUBITS = 9          # 9 qubit per griglia 3x3
const N_STATES = 512        # 2^9 stati senza ancilla

"""
Ritorna Set degli stati (0-511) che contengono una linea verticale.
Colonne: {0,3,6}, {1,4,7}, {2,5,8}
"""
function marked_states_vertical()
    good = Set{Int}()
    for col_bits in ([0,3,6], [1,4,7], [2,5,8])
        for x in 0:(N_STATES-1)
            if all(b -> (x >> b) & 1 == 1, col_bits)
                push!(good, x)
            end
        end
    end
    return good
end

#Definizioni oracoli come stati marcati (da 0 a 511) per la griglia 3x3

"""
Ritorna Set degli stati che contengono un quadrato 2x2.
Quadrati: {0,1,3,4}, {1,2,4,5}, {3,4,6,7}, {4,5,7,8}
"""
function marked_states_square()
    good = Set{Int}()
    for sq_bits in ([0,1,3,4], [1,2,4,5], [3,4,6,7], [4,5,7,8])
        for x in 0:(N_STATES-1)
            if all(b -> (x >> b) & 1 == 1, sq_bits)
                push!(good, x)
            end
        end
    end
    return good
end

"""
Ritorna Set degli stati che contengono una diagonale.
Diagonali: {0,4,8}, {2,4,6}
"""
function marked_states_diagonal()
    good = Set{Int}()
    for diag_bits in ([0,4,8], [2,4,6])
        for x in 0:(N_STATES-1)
            if all(b -> (x >> b) & 1 == 1, diag_bits)
                push!(good, x)
            end
        end
    end
    return good
end

"""
Ritorna Set con solo lo stato "full" (tutti i bit a 1).
"""
function marked_states_full()
    return Set{Int}([511])  # 111111111 in binario
end

"""
Crea la base per N_QUBITS qubit (spazio di Hilbert 512-dimensionale).
"""
function create_basis()
    return tensor([SpinBasis(1//2) for _ in 1:N_QUBITS]...)
end

"""
Costruisce l'operatore oracle matrice diagonale.
Oracle: applica fase -1 agli stati marcati, +1 agli altri.
"""
function build_oracle_operator(marked::Set{Int}, basis)
    d = ones(ComplexF64, N_STATES)
    for m in marked
        d[m + 1] = -1.0  # Julia è 1-indexed
    end
    return DenseOperator(basis, diagm(d))
end

"""
Costruisce l'operatore di diffusione di Grover.
Diffusore: 2|s⟩⟨s| - I, dove |s⟩ = H^⊗n |0⟩
"""
function build_diffusion_operator(basis)
    s = ones(ComplexF64, N_STATES) / sqrt(N_STATES)
    return DenseOperator(basis, 2 * s * s' - LinearAlgebra.I(N_STATES))
end

"""
Crea un registro QuantumSavory con N_QUBITS qubit.
- QuantumOpticsRepr (necessario per oracle non-Clifford)
- background: Depolarization con parametro τ (tempo caratteristico)
"""
function create_register(τ_depol::Float64)
    return Register(
        [Qubit() for _ in 1:N_QUBITS],
        [QuantumOpticsRepr() for _ in 1:N_QUBITS],
        [Depolarization(τ_depol) for _ in 1:N_QUBITS]
        #bit flip not supported yet from quantumsavory
        #[BitFlip(τ_depol) for _ in 1:N_QUBITS]
    )
end

"""
Crea un registro senza rumore (τ → ∞).
"""
function create_noiseless_register()
    return Register(
        [Qubit() for _ in 1:N_QUBITS],
        [QuantumOpticsRepr() for _ in 1:N_QUBITS]
    )
end

"""
Calcola il numero ottimale di iterazioni di Grover (formula esatta).
θ = arcsin(√(M/N))
k = round(π/(4θ) - 0.5)
"""
function optimal_iterations(n_marked::Int)
    θ = asin(sqrt(n_marked / N_STATES))
    return max(1, round(Int, π / (4 * θ) - 0.5))
end

# IMPORTANTE: Impostato a 0 perché i valori estratti da Qiskit (depth)
# includono già sia l'Oracolo che il Diffusore fusi e ottimizzati globalmente.
const GATES_EFFECTIVE_DIFFUSER = 0

# Profondità totale del circuito estratta da transpile(optimization_level=3). Sono comprese anche tutte le iterazioni
const GATES_EFFECTIVE_ORACLE = Dict(
    "vertical" => 3312,  
    "square"   => 6638,  
    "diagonal" => 767,   
    "full"     => 2288  #38908/17   
)

"""
Formula base: converte i gate fisici effettivi in tempo equivalente 
per l'avanzamento del decadimento continuo in QuantumSavory.
"""
function calculate_equivalent_time(effective_gates::Int, n_qubits::Int=N_QUBITS)
    return Float64(effective_gates) / Float64(n_qubits)
end

const GATE_TIME = 1.0              
const DIFFUSER_TIME = calculate_equivalent_time(GATES_EFFECTIVE_DIFFUSER)

const ORACLE_TIMES = Dict(
    name => calculate_equivalent_time(gates) for (name, gates) in GATES_EFFECTIVE_ORACLE
)

"""
Normalizza la density matrix per assicurare tr(ρ) = 1.
Necessario dopo manipolazioni raw per evitare errori in uptotime!
"""
function normalize_state!(state)
    if state isa Operator
        tr_val = tr(state.data)
        if abs(tr_val) > 1e-10
            state.data ./= tr_val
        end
    end
    return state
end

"""
Esegue l'algoritmo di Grover usando QuantumSavory Register.

- time=t in ogni apply! per far avanzare il rumore
- uptotime!(reg[i], t) prima di manipolare lo stato raw
- Incrementa t per ogni operazione

Parametri:
- marked: Set degli stati target
- τ_depol: tempo caratteristico depolarizzazione (Inf = no noise)
- oracle_time: tempo (gate equivalenti) per l'oracle
"""
function run_grover(marked::Set{Int}; 
                    τ_depol::Float64=Inf,
                    oracle_time::Float64=50.0)
    
    n_marked = length(marked)
    n_iter = optimal_iterations(n_marked)
    
    # Crea registro con o senza rumore
    if τ_depol == Inf
        reg = create_noiseless_register()
    else
        reg = create_register(τ_depol)
    end
    
    # Crea operatori + oracoli + diffusore
    basis = create_basis()
    U_oracle = build_oracle_operator(marked, basis)
    U_diffuse = build_diffusion_operator(basis)
    
    t = 0.0  # Clock per time tracking
    
    # Inizializza tutti i qubit in |0⟩ e applica Hadamard
    for i in 1:N_QUBITS
        initialize!(reg[i], Z1; time=t)
        t += GATE_TIME
        apply!(reg[i], H; time=t)
    end
    
    # Applica CNOT² per forzare il merge di tutti i qubit in uno stato congiunto
    # (necessario per applicare oracle/diffusore come operatori globali)
    for i in 2:N_QUBITS
        apply!([reg[1], reg[i]], CNOT; time=t)
        apply!([reg[1], reg[i]], CNOT; time=t)  # Undo logic, keep merged
    end
    
    # iterazioni di grover
    for iter in 1:n_iter
        # ORACLE
        # Avanza il tempo per l'oracle (usa parametro oracle_time per calibrazione)
        t += oracle_time
        # Applica noise fino al tempo corrente su tutti i qubit
        for i in 1:N_QUBITS
            uptotime!(reg[i], t)
        end
        # Applica oracle come operatore raw
        raw_state = reg.staterefs[1].state[]
        if raw_state isa Ket
            raw_state = U_oracle * raw_state
        else  # Operator (density matrix)
            raw_state = Operator(raw_state.basis_l, raw_state.basis_r,
                                 U_oracle.data * raw_state.data * U_oracle.data')
        end
        raw_state = normalize_state!(raw_state)  # Normalizza per evitare drift tr(ρ)
        reg.staterefs[1].state[] = raw_state
        

        # DIFFUSORE
        # Avanza il tempo per il diffusore
        t += DIFFUSER_TIME 
        # Applica noise fino al tempo corrente
        for i in 1:N_QUBITS
            uptotime!(reg[i], t)
        end
        # Applica diffusore come operatore raw
        raw_state = reg.staterefs[1].state[]
        if raw_state isa Ket
            raw_state = U_diffuse * raw_state
        else  # Operator (density matrix)
            raw_state = Operator(raw_state.basis_l, raw_state.basis_r,
                                 U_diffuse.data * raw_state.data * U_diffuse.data')
        end
        raw_state = normalize_state!(raw_state)  # Normalizza per evitare drift tr(ρ)
        reg.staterefs[1].state[] = raw_state
    end
    
    # Ritorna lo stato finale
    return reg.staterefs[1].state[]
end

"""
Calcola probabilità direttamente dallo stato finale.
"""
function compute_success_probability(marked::Set{Int}; 
                                     τ_depol::Float64=Inf,
                                     oracle_time::Float64=50.0)
    
    final_state = run_grover(marked; 
                             τ_depol=τ_depol, 
                             oracle_time=oracle_time)
    
    # Estrai probabilità
    if final_state isa Ket
        probs = abs2.(final_state.data)
    else  # Operator (density matrix)
        probs = real.(diag(final_state.data))
    end
    
    # Somma probabilità degli stati marcati
    success_prob = sum(probs[m + 1] for m in marked)
    return success_prob * 100.0
end

# MAIN - TEST COMPLETO
function main()
    println("ESECUZIONE TEST")
    
    # Definizione oracle
    oracles = [
        ("vertical", marked_states_vertical()),
        ("square", marked_states_square()),
        ("diagonal", marked_states_diagonal()),
        ("full", marked_states_full())
    ]
    
    # IMPORTANTE: CALIBRAZIONE τ PER COERENZA CON QISKIT
    # In Qiskit: p = probabilità di errore PER SINGOLO GATE
    #   → Con 50 gate, errore totale ≈ 50×p (per p piccoli)
    #
    # In QuantumSavory: rumore continuo con decay esponenziale
    #   → p(t) = 1 - exp(-t/τ)
    #
    # Per rendere i modelli equivalenti, calibriamo τ affinché in 1 unità
    # di tempo (= 1 gate, dato GATE_TIME=1.0) ci sia probabilità p di errore:
    #   p = 1 - exp(-1/τ)  →  τ = -1 / ln(1-p)
    #
    # Così l'Oracle (t=50) accumula errore come ~50 gate in Qiskit,
    # e i risultati sono direttamente confrontabili.
    
    compute_tau_per_gate(p::Float64) = -1.0 / log(1.0 - p)

    τ_values = [
        (0.001, compute_tau_per_gate(0.001)),  # τ ≈ 999.5
        (0.005, compute_tau_per_gate(0.005)),  # τ ≈ 199.5
        (0.01,  compute_tau_per_gate(0.01)),   # τ ≈ 99.5
        (0.05,  compute_tau_per_gate(0.05))    # τ ≈ 19.5
    ]
    
    # Risultati
    results = Dict()
    
    for (name, marked) in oracles
        println("ORACLE: $name")
        
        n_marked = length(marked)
        n_iter = optimal_iterations(n_marked)
        classical_prob = n_marked / N_STATES * 100.0
        oracle_t = ORACLE_TIMES[name]  # Tempo totale per tutte le iterazioni
        
        println("  Stati target: $n_marked / $N_STATES")
        println("  Iterazioni ottimali: $n_iter")
        println("  Oracle time (gate equiv.): $(oracle_t/100) s")
        println("  Probabilità classica (random): $(round(classical_prob, digits=2))%")
        
        # NOISELESS
        println("\n  [NOISELESS]")
        ideal_prob = compute_success_probability(marked; oracle_time=oracle_t)
        println("    Grover: $(round(ideal_prob, digits=1))%")
        println("    Prob. Ratio: $(round(ideal_prob / classical_prob, digits=2))x")
        
        # DEPOLARIZING NOISE
        println("\n  [DEPOLARIZING NOISE]")
        for (p_label, τ) in τ_values
            noisy_prob = compute_success_probability(marked; τ_depol=τ, oracle_time=oracle_t)
            deg = (ideal_prob - noisy_prob) / ideal_prob * 100.0
            println("    p≈$p_label (τ=$(round(τ, digits=1))): $(round(noisy_prob, digits=1))%  (deg: $(round(deg, digits=1))%)")
        end

        results[name] = (n_marked, classical_prob, ideal_prob)
    end
    
    # RIEPILOGO
    println("RIEPILOGO")
    println("Oracle       Targets  Classical    Grover       Prob. Ratio")
    for (name, marked) in oracles
        n_marked, classical, ideal = results[name]
        prob_ratio = ideal / classical
        println("$(rpad(name, 12)) $(rpad(string(n_marked), 8)) " *
                "$(rpad(string(round(classical, digits=1))*"%", 12)) " *
                "$(rpad(string(round(ideal, digits=1))*"%", 12)) " *
                "$(round(prob_ratio, digits=2))x")
    end
    
    # GRAFICO
    println("\nGenerazione grafico...")
    
    oracle_names = [name for (name, _) in oracles]
    ideal_rates = [results[name][3] for name in oracle_names]
    classical_rates = [results[name][2] for name in oracle_names]
    
    # Calcola tassi con rumore per il grafico
    # Usa τ calibrato per p=0.01 
    τ_for_plot = compute_tau_per_gate(0.01)  # ≈ 99.5
    depol_rates = Float64[]
    
    for (name, marked) in oracles
        oracle_t = ORACLE_TIMES[name]
        push!(depol_rates, compute_success_probability(marked; τ_depol=τ_for_plot, oracle_time=oracle_t))
    end
    
    x = 1:4
    bw = 0.25
    
    plt = bar(x .- bw/2, classical_rates, label="Classical", bar_width=bw, color=:gray, alpha=0.6,
              xlabel="Oracle", ylabel="Success Rate (%)",
              title="Grover's Algorithm - QuantumSavory Implementation",
              xticks=(1:4, oracle_names), ylims=(0, 105), legend=:topright)
    bar!(x .+ bw/2, ideal_rates, label="Grover Ideal", bar_width=bw, color=:green)
    bar!(x .+ 3*bw/2, depol_rates, label="Depolarizing (p=0.01)", bar_width=bw, color=:orange)
    
    savefig(plt, joinpath(@__DIR__, "grover_quantumsavory_correct.png"))
    println("Grafico salvato: grover_quantumsavory_correct.png")
    
    println("IMPLEMENTAZIONE COMPLETATA")
    
end

# Esegui se chiamato direttamente
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
