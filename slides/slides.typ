#import "@preview/typslides:1.3.0": *
#import "@preview/tablex:0.0.9": *

// Project configuration
#show: typslides.with(
  ratio: "16-9",
  theme: "purply",
  font: "Fira Sans",
  font-size: 20pt,
  link-style: "color",
  show-progress: true,
)


// The front slide is the first slide of your presentation
#front-slide(
  title: "Programmation Système",
  subtitle: [24 Novembre 2025],
  authors: "Thomas Varin, Théotime Turmel, Mathias Loiseau",
  info: [#link("https://github.com/zBlxst/Programmation_systeme_m2_secrets")],
)


#slide(title:"Introduction à la programmation système")[
  - Ensemble d'appels système (syscalls)
  - Interaction directe avec le noyau
  - Gestion bas niveau : mémoire, processus, threads, fichiers
]

#table-of-contents()

#title-slide[Appel système]

#slide(title:"Appel système")[
  - Instruction du processeur (syscall/int 0x80/scall/swi NR/...)
  - Appel d'une fonction du noyau
  - Permet l'utilisation des fonctionnalités du noyau
]

#set raw(lang:"C", block:true)
#slide(title:"Utilisation")[
  - Utilisation des fonctions de "binding" du langage : *read*, *write*, *execve*, ...
  - Utilisation de la fonction `syscall()` de `<unistd.h>`
  - Écriture de code assembleur pour directement appeler l'instruction *syscall*.

]

#slide(title:"Exemples d'appels système")[
  - *Fork* (0x39) : Permet la duplication du processus. 
  
  - *Execve* (0x3b) : Remplace l'image du processus par celle d'un autre programme.
  
  - *Pipe* (0x16) : Crée un tube (pipe) bi-directionnel pour la communication entre processus.
  
  - *Dup2* (0x21) : Permet la création/le remplacement d'un descripteur de fichier.
  
  Liste exhaustive : https://syscall.sh/
]

#slide(title:"Utilisation de l'instruction syscall")[
  ```asm
; execve("/bin/sh", NULL, NULL)

	xor rsi, rsi
	push rsi
	pop rdx

	push rsi
	mov rdi, 0x68732f2f6e69622f ; /bin//sh
	push rdi
	mov rdi, rsp

	push 0x3b
	pop rax ; SYS_execve
	syscall
  ```

  https://github.com/voydstack/shellcoding/blob/master/x64/shell/shell.asm
  
]

#slide(title:"Changement de contexte")[
  - Passage de *userland* à *kernelland*
  - Sauvegarde des registres
  - Pile et tas séparés
  - Aucune restriction : le noyau doit vérifier les permissions (capacités)
]


#title-slide[Processus]

#slide(title:"Définition")[
  - Entité d'exécution isolée
  - Défini par son *PID*
  - Possède son propre espace mémoire :
    - code, données, heap, stack
  - Contient un contexte d'exécution :
    - registres, compteur ordinal (program counter), état du processus
  - Géré par l'ordonnanceur du système d'exploitation
]

#set raw(lang:"sh", block:true)
#slide(title:"Création d'un processus")[
  - Un processus est créé via l'appel système `fork()`
  - `fork()` duplique le processus courant
  - Retours possibles :
    - Dans le *parent* : retour = PID de l'enfant
    - Dans l'*enfant* : retour = 0
    - En cas d'erreur : retour = -1
]

#set raw(lang:"C", block:true)
#slide(title:"Exemple minimal avec fork()")[
  ```C
  #include <unistd.h>
  #include <stdio.h>

  int main() {
    pid_t pid = fork();

    if (pid == 0) {
      printf("Processus enfant : pid=%d\n", getpid());
    } else {
      printf("Processus parent : pid enfant=%d\n", pid);
    }
  }
  ```
]

#slide(title:"Communication inter-processus")[
  Différentes méthodes:
  - Pipes: `popen()`, `pclose()`
  - Coprocesses
  - FIFOs (unnamed pipes)
  - Message queues
  - Shared memory
  - Sockets 
]

#title-slide[Threads]

#slide(title: "Pourquoi des threads ?")[
  - Moins coûteux que les processus
  - Intercommunication simple
  - Meilleure performance en multicoeurs
]

#set raw(lang:"C", block:true)
#slide(title: "Création et terminaison d'un thread")[
  Norme POSIX
  - Création via `int pthread_create(
    pthread_t *restrict thread,
    const pthread_attr_t *restrict attr,
    void *(*start_routine)(void *),
    void *restrict arg
    );`
  - Le thread est affecté à une fonction `void* fun(void* args)`
  - `pthread_join(thread)` : attendre un thread
  - `pthread_exit()` : terminer explicitement
  
]


#slide(title: [Exemple : tri #strike[bubulles] pair-impair])[

  #cols(columns: (2fr, 2fr, 4fr), gutter: 2em)[

    #align(center)[#image("img/Bubble_sort_animation.gif")
    Tri à bulles]

  ][
    #align(center)[#image("img/Odd_even_sort_animation.gif")
    Tri pair-impair]
  ][
    - Une phase paire :
    $(x_0<->^?x_1), (x_2 <->^?x_3),...$

    - Une phase impaire :
    $(x_1 arrow.l.r^? x_2), (x_3 arrow.l.r^?x_4),...$
    
    - Toujours $cal(O)(n^2)$ opérations, mais réparties en $p$ threads
  ]
]

#slide(title: "Problèmes de concurrence")[
  - Accès simultané à une même ressource
  - Conditions de course
  - Corruption mémoire
```
void* increment(void* arg) {
  for (int i = 0; i < 1000; i++) counter++;    // Section partagée
  return NULL;
}
```
]

#slide(title: "Solutions aux problèmes de concurrence")[
  - Mutex : Verrou pour protéger une section critique
    - `pthread_mutex_lock()`
    - `pthread_mutex_unlock()`

  - Sémaphores : compteur de ressources disponibles
    - `sem_init()`, `sem_wait()`, `sem_post()`

  - RW-Locks (verrous lecteur-rédacteur)
    - Plusieurs lecteurs possibles, un seul rédacteur
    - `pthread_rwlock_rdlock()`, `pthread_rwlock_wrlock()`
]


#slide(title: "Récapitulatif processus vs threads")[
  #scale(225%, origin:left)[#align(center)[
    #tablex(
    columns:3,
    align:center,
    hlinex(end:0),
    vlinex(end:0), [], [Processus], [Thread], vlinex(end:0),
    [Mémoire], [Séparée], [Partagée],
    [Communication], [Difficile], [Directe],
    [Isolation], [Forte], [Faible,],
    [Identité], [*PID*], [`pthread_t`],
    hlinex(end:0)
  )
  ]]  
]

#focus-slide[
  Comment sont implémentés les threads ?
]

#set raw(lang:none, block:true)
#slide(title:"Implémentation des threads sous Linux")[
  Extrait de *pthreads(7) — Linux manual page*
  ```
  Linux implementations of POSIX threads
       Over time, two threading implementations have been provided by the
       GNU C library on Linux:
après mallocaprès malloc
       LinuxThreads
              ...

       NPTL (Native POSIX Threads Library)
              This is the modern Pthreads implementation...

       Both of these are so-called 1:1 implementations, meaning that each
       thread maps to a kernel scheduling entity.  Both threading
       implementations employ the Linux clone(2) system call.  In NPTL,
       thread synchronization primitives (mutexes, thread joining, and so
       on) are implemented using the Linux futex(2) system call.

  ```
  
]

#title-slide[Autres aspects de programmation système]

#slide(title:"bit Set-User-ID (SUID)")[
  - Pour les fichiers exécutables
  - Tout utilisateur exécutant un fichier SUID obtient comme effective user ID l'userid du propriétaire
  - SUID bit indiqué par un s dans les permissions du fichier
  - On peut activer le bit SUID avec la commande ``` chmod u+s file ``` si on dispose de droits suffisants (propriétaire du fichier ou root en général)
]

#set raw(lang:"C", block:true)
#slide(title:"exemple de programme SUID 1/2")[
  #image("img/permissions.png")
  - Ici, les deux programmes sont obtenus en compilant le code suivant: ``` #include <stdio.h>
#include <unistd.h>

int main() {
  int effectiveID = geteuid();
  int realID = getuid();
  printf("Effective id: %d, Real id: %d\n", effectiveID, realID);  
}
```
]

#slide(title:"exemple de programme SUID 2/2")[
  - Seul whoami2 possède le SUID bit. Voici le résultat de l'exécution de ces 2 programmes: 
    #image("img/execution_whoami.png")
  - Lors de l'exécution, euid devient l'uid du propriétaire (ici, root)
  - En utilisant la fonction setuid(), on peut ensuite remplacer notre real user id par celle du propriétaire
]

#slide(title:"Contrôle d'utilisation des ressources")[
  - On peut limiter la consommation de différentes resources utilisées par un processus
  - Lorsqu'un processus est créé, il obtient les mêmes limitations que son processus parent
  - Quelles sont les ressources que nous pouvons limiter ?
]

#slide(title:"Types de resources")[
  #image("img/resources.png", alt: "Les différents types de ressources et leur support pour différentes OS, source: Advanced Programming in the UNIX Environment 3rd ed")
  - RLIMIT_CPU limite le temps CPU d'un programme (et le termine automatiquement si la limite de temps est dépassée)
  - RLIMIT_DATA limite la taile du segment DATA
  - RLIMIT_FSIZE limite la taille d'un fichier créé par le processus
  - RLIMIT_STACK limite la taille maximale du stack
]

#slide(title:"Exemple de limitation")[
  - Pour intéragir avec les limites de ressources, on utilise les fonctions suivantes:
  ``` int getrlimit(int resource, struct rlimit *rlptr);
  int setrlimit(int resource, const struct rlimit *rlptr);
  
  struct rlimit {
    rlim_t rlim_cur; /* soft limit */
    rlim_t rlim_max; /* hard limit */
  }```
  Soft limit est la valeur qu'on attribue au processus tandis que Hard limit est la valeur maximale que peut s'attribuer le processus s'il n'est pas superuser.
]

#slide(title:"Exemple de limitation")[
  Exemple:
  ``` #include <sys/resources.h>
  int main() {
    struct rlimit limit;
    limit.rlim_cur = 5;
    limit.rlim_max = 5;
    int errorcode = setrlimit(RLIMIT_CPU, &limit);
  }
  ```
  Si l'appel à setrlimit réussit, alors le temps CPU maximum donné à ce processus est de 5 secondes.
]

#title-slide[Capacités Linux]

#slide(title:"Généralités")[
  - Division des permissions *root* en 41 parties
  - Granularité des privilèges
  - Permet de réaliser des actions privilégiés avec des comptes utilisateurs
  - Utilisées lors des appels système
]

#slide(title:"Ensemble de capacités des processus")[
  - Effective : capacités actives
  - Permitted : capacités utilisables
  - Inheritable : capacités pouvant être transmises
  - Ambient : capacités transmises par défaut
  - Bounding : capacités maximales
]

#slide(title:"Ensemble de capacités des fichiers")[
  - Permitted : capacités ajoutées à l'ensemble *Permitted* du processus
  - Inheritable : capacités ajoutées à l'ensemble *Permitted* du processus si celui les possède dans son ensemble *Inheritable*
  Un bit *effective* peut être activé pour copier les capacités *Permitted* dans l'ensemble *Effective*.
]

#slide(title:"Évolution des capacités lors d'un appel système execve")[
  $P'_("ambient")("cap") = cases(
    0 "si le fichier est privilégié (capacités/[S/G]uid)",
    P_("ambient")("cap") "sinon"
  )$

  #v(50pt)
  
  $P'_("permitted")("cap") = cases(
    F_("permitted")("cap") "si" P_("bouding")("cap"),
    F_("inheritable")("cap") "si" P_("inheritable")("cap"),
    P_("ambient")("cap") "sinon"
  )$

  #v(50pt)

  $P'_("effective")("cap") = cases(
    P'_("permitted")("cap") "si" F_("effective"),
    P_("ambient")("cap") "sinon"
  )$

]

#slide(title:"Appels systèmes relatifs aux capacités")[
  - Processus : *capget* (0x7d) et *capset* (0x7e)
  - Fichiers : *getxattr* (0xbf) et *setxattr* (0xbc)
]

#slide(title:"Exemples de capacités")[
  - CAP_SETUID : Permet de changer le RUID du processus
  - CAP_SYS_PTRACE : Permet de débugger tous les processus
  - CAP_NET_RAW : Permet de créer des raw sockets
  - CAP_RAW_IO : Permet de communiquer directement dans les ports physiques
]

#focus-slide[
  #set text(size:2cm)
  Merci pour votre attention !
]