import random
import time
import matplotlib.pyplot as plt
import numpy as np

#ORACLES 
def vertical_oracle(matrix):
    for col in range(3):
        if all(matrix[row][col] == 1 for row in range(3)):
            return True
    return False

def square_oracle(matrix):
    for row in range(2):
        for col in range(2):
            if (matrix[row][col] == 1 and matrix[row][col + 1] == 1 and
                matrix[row + 1][col] == 1 and matrix[row + 1][col + 1] == 1):
                return True
    return False

def diagonal_oracle(matrix):
    if (matrix[0][0] == 1 and matrix[1][1] == 1 and matrix[2][2] == 1):
        return True
    if (matrix[0][2] == 1 and matrix[1][1] == 1 and matrix[2][0] == 1):
        return True
    return False

def full_oracle(matrix):
    for row in range(3):
        for col in range(3):
            if matrix[row][col] == 0:
                return False
    return True



#SEARCH METHODS
def sequenza(oracle):
    count = 0
    for code in range(512):
        count += 1
        matrix = generate_matrix(code)
        if oracle(matrix):
            #print_matrix(matrix)
            return count
        
def sequenza_casuale(oracle):
    count = 0
    code = random.randint(0, 511)
    for i in range(512):
        count += 1
        matrix = generate_matrix((code + i) % 512)
        if oracle(matrix):
            #print_matrix(matrix)
            return count

def casuale(oracle):
    count = 0
    while True:
        count += 1
        matrix = random_matrix()
        if oracle(matrix):
            #print_matrix(matrix)
            return count
        
def casuale_senza_ripetizioni(oracle):
    count = 0
    seen = set()
    while True:
        code = random.randint(0, 511)
        if code in seen:
            continue
        seen.add(code)
        matrix = generate_matrix(code)
        count += 1
        if oracle([list(row) for row in matrix]):
            #print_matrix([list(row) for row in matrix])
            return count
        
#UTILITY FUNCTIONS
def generate_matrix(code):
    matrix = [[0]*3 for _ in range(3)]
    for i in range(9):
        if code & (1 << i):
            matrix[i // 3][i % 3] = 1
            
    return matrix
    
def random_matrix():
    return generate_matrix(random.randint(0, 511))

def print_matrix(matrix):
    for row in matrix:
        print(' '.join(map(str, row)))
    print()
    
#MAIN EXPERIMENT
def main():
    oracles = [vertical_oracle, square_oracle, diagonal_oracle, full_oracle]
    oracle_names = ['Vertical', 'Square', 'Diagonal', 'Full']
    methods = [sequenza, sequenza_casuale, casuale, casuale_senza_ripetizioni]
    method_names = ['Sequenza', 'Sequenza Casuale', 'Casuale', 'Casuale Senza Rip.']
    numero_prove = 10000
    
    # Matrici per memorizzare i risultati
    avg_results = np.zeros((len(oracles), len(methods)))
    min_results = np.zeros((len(oracles), len(methods)))
    max_results = np.zeros((len(oracles), len(methods)))
    time_results = np.zeros((len(oracles), len(methods)))
    
    for i, oracle in enumerate(oracles):
        for j, method in enumerate(methods):
            totale_tentativi = 0
            min_tentativi = 200000000
            max_tentativi = 0
            totale_tempo_esecuzione = 0
            print(f"Using {method.__name__} with {oracle.__name__}:")
            start = time.time()
            for _ in range(numero_prove):
                attempts = method(oracle)
                if attempts < min_tentativi:
                    min_tentativi = attempts
                if attempts > max_tentativi:
                    max_tentativi = attempts
                totale_tentativi += attempts
            totale_tempo_esecuzione = time.time() - start
            
            avg = totale_tentativi / numero_prove
            avg_results[i, j] = avg
            min_results[i, j] = min_tentativi
            max_results[i, j] = max_tentativi
            time_results[i, j] = totale_tempo_esecuzione
            
            print(f"Average: {avg}, Min: {min_tentativi}, Max: {max_tentativi}, Tempo: {totale_tempo_esecuzione / totale_tentativi}\n")
    
    # Creazione grafici
    plot_comparison_charts(avg_results, min_results, max_results, time_results, 
                          oracle_names, method_names)

def plot_comparison_charts(avg_results, min_results, max_results, time_results,
                           oracle_names, method_names):
    """Genera grafici di confronto tra metodi e oracoli"""
    
    x = np.arange(len(oracle_names))
    width = 0.2
    colors = ['#2ecc71', '#3498db', '#e74c3c', '#9b59b6']
    
    # Plot 1: Confronto Media Tentativi per Oracolo
    fig1, ax1 = plt.subplots(figsize=(12, 6))
    for i, method_name in enumerate(method_names):
        bars = ax1.bar(x + i*width, avg_results[:, i], width, label=method_name, color=colors[i])

        for bar, val in zip(bars, avg_results[:, i]):
            ax1.annotate(f'{val:.1f}', xy=(bar.get_x() + bar.get_width()/2, bar.get_height()),
                        ha='center', va='bottom', fontsize=8, rotation=45)
    
    ax1.set_xlabel('Oracolo', fontsize=12)
    ax1.set_ylabel('Media Tentativi', fontsize=12)
    ax1.set_title('Confronto Media Tentativi per Metodo e Oracolo', fontsize=14, fontweight='bold')
    ax1.set_xticks(x + width * 1.5)
    ax1.set_xticklabels(oracle_names)
    ax1.legend(loc='upper left')
    ax1.grid(axis='y', alpha=0.3)
    plt.tight_layout()
    plt.savefig('confronto_media_tentativi.png', dpi=150)
    plt.show()
    
    # Plot 2: Tempo di Esecuzione Totale
    fig3, ax3 = plt.subplots(figsize=(12, 6))
    for i, method_name in enumerate(method_names):
        bars = ax3.bar(x + i*width, time_results[:, i], width, label=method_name, color=colors[i])
    
    ax3.set_xlabel('Oracolo', fontsize=12)
    ax3.set_ylabel('Tempo Totale (s)', fontsize=12)
    ax3.set_title('Tempo di Esecuzione Totale per Metodo e Oracolo', fontsize=14, fontweight='bold')
    ax3.set_xticks(x + width * 1.5)
    ax3.set_xticklabels(oracle_names)
    ax3.legend(loc='upper left')
    ax3.grid(axis='y', alpha=0.3)
    plt.tight_layout()
    plt.savefig('confronto_tempo_esecuzione.png', dpi=150)
    plt.show()
    
if __name__ == "__main__":            
    main()