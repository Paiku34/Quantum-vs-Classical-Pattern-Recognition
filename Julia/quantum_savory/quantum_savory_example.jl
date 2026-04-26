# QuantumSavory - Simulazione di Reti Quantistiche
# Framework per simulare protocolli di comunicazione quantistica distribuita

# Installazione dei pacchetti necessari (eseguire una sola volta)
# using Pkg
# Pkg.add("QuantumSavory")
# Pkg.add("ConcurrentSim")
# Pkg.add("ResumableFunctions")

using QuantumSavory
using ConcurrentSim
using ResumableFunctions

# =============================================================================
# Esempio 1: Creazione di un Registro Quantistico
# =============================================================================

println("=" ^ 60)
println("Esempio 1: Registro Quantistico Base")
println("=" ^ 60)

# Creare un registro quantistico con 3 slot
reg = Register(3)
println("Registro creato con $(nsubsystems(reg)) slot")

# Inizializzare il primo slot con uno stato |0⟩
initialize!(reg[1], Z1)
println("Slot 1 inizializzato con stato |0⟩")

# Inizializzare il secondo slot con uno stato |+⟩
initialize!(reg[2], X1)
println("Slot 2 inizializzato con stato |+⟩")

# =============================================================================
# Esempio 2: Operazioni Quantistiche
# =============================================================================

println("\n" * "=" ^ 60)
println("Esempio 2: Operazioni Quantistiche")
println("=" ^ 60)

# Applicare un gate Hadamard al primo slot
apply!(reg[1], H)
println("Gate Hadamard applicato allo slot 1")

# Applicare un gate CNOT tra slot 1 (controllo) e slot 3 (target)
initialize!(reg[3], Z1)
apply!((reg[1], reg[3]), CNOT)
println("Gate CNOT applicato: slot 1 (controllo) → slot 3 (target)")

# =============================================================================
# Esempio 3: Creazione di una Rete Quantistica
# =============================================================================

println("\n" * "=" ^ 60)
println("Esempio 3: Rete Quantistica con Entanglement")
println("=" ^ 60)

# Definire una rete con 2 nodi, ognuno con 2 slot quantistici
net = RegisterNet([
    Register(2),  # Nodo Alice
    Register(2)   # Nodo Bob
])

println("Rete creata con $(length(net.registers)) nodi")

# Accedere ai registri di Alice e Bob
alice = net[1]
bob = net[2]

# Creare uno stato di Bell entangled tra Alice e Bob
# |Φ+⟩ = (|00⟩ + |11⟩)/√2 creato con H + CNOT
initialize!(alice[1], Z1)
initialize!(bob[1], Z1)
apply!(alice[1], H)
apply!((alice[1], bob[1]), CNOT)
println("Stato di Bell |Φ+⟩ creato tra Alice[1] e Bob[1]")

# =============================================================================
# Esempio 4: Simulazione con Eventi Discreti
# =============================================================================

println("\n" * "=" ^ 60)
println("Esempio 4: Simulazione con Eventi Discreti")
println("=" ^ 60)

# Definire un protocollo semplice usando ResumableFunctions
@resumable function simple_protocol(sim::Simulation, reg::Register)
    println("  t=$(now(sim)): Inizializzazione qubit")
    initialize!(reg[1], Z1)

    @yield timeout(sim, 1.0)  # Attendi 1 unità di tempo

    println("  t=$(now(sim)): Applicazione gate H")
    apply!(reg[1], H)

    @yield timeout(sim, 0.5)

    println("  t=$(now(sim)): Misurazione")
    result = project_traceout!(reg[1], Z)
    println("  t=$(now(sim)): Risultato misurazione = $result")
end

# Eseguire la simulazione
sim = Simulation()
reg_sim = Register(1)
@process simple_protocol(sim, reg_sim)
run(sim)

# =============================================================================
# Esempio 5: Protocollo di Teletrasporto Quantistico
# =============================================================================

println("\n" * "=" ^ 60)
println("Esempio 5: Teletrasporto Quantistico")
println("=" ^ 60)

function teleportation_demo()
    # Creare registri per Alice (2 qubit) e Bob (1 qubit)
    alice = Register(2)
    bob = Register(1)

    # Alice prepara lo stato da teletrasportare nel suo primo qubit
    # Stato arbitrario: |ψ⟩ = α|0⟩ + β|1⟩
    initialize!(alice[1], Z1)
    apply!(alice[1], H)  # Creiamo uno stato |+⟩ come esempio
    println("Alice prepara lo stato |+⟩ da teletrasportare")

    # Creare coppia di Bell tra Alice[2] e Bob[1]
    # |Φ+⟩ = (|00⟩ + |11⟩)/√2
    initialize!(alice[2], Z1)
    initialize!(bob[1], Z1)
    apply!(alice[2], H)
    apply!((alice[2], bob[1]), CNOT)
    println("Coppia di Bell creata tra Alice e Bob")

    # Alice applica CNOT tra il suo stato e la sua metà della coppia di Bell
    apply!((alice[1], alice[2]), CNOT)
    println("Alice applica CNOT")

    # Alice applica Hadamard al primo qubit
    apply!(alice[1], H)
    println("Alice applica Hadamard")

    # Alice misura i suoi due qubit
    m1 = project_traceout!(alice[1], Z)
    m2 = project_traceout!(alice[2], Z)
    println("Alice misura: m1=$m1, m2=$m2")

    # Bob applica le correzioni basate sui risultati di Alice
    if m2 == 2  # |1⟩
        apply!(bob[1], X)
        println("Bob applica correzione X")
    end
    if m1 == 2  # |1⟩
        apply!(bob[1], Z)
        println("Bob applica correzione Z")
    end

    println("Teletrasporto completato! Lo stato è ora nel registro di Bob")
end

teleportation_demo()

# =============================================================================
# Esempio 6: Canale Quantistico con Rumore
# =============================================================================

println("\n" * "=" ^ 60)
println("Esempio 6: Modelli di Rumore")
println("=" ^ 60)

# QuantumSavory supporta vari modelli di rumore per simulazioni realistiche
reg_noisy = Register(1)
initialize!(reg_noisy[1], Z1)
apply!(reg_noisy[1], H)

println("QuantumSavory supporta modelli di rumore realistici:")
println("  - Decoerenza T1/T2")
println("  - Canale depolarizzante")
println("  - Errori di gate")
println("  - Perdita di fotoni nei canali ottici")

println("\n" * "=" ^ 60)
println("Simulazione completata!")
println("=" ^ 60)
