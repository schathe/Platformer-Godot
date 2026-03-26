# Guide Complet : Platformer Godot en Formes Simples

### Introduction

Tu as raison de vouloir te concentrer sur la mécanique plutôt que l'art. C'est la meilleure approche pour progresser rapidement en gamedev. Ce document synthétise les idées de gameplay pour ton platformer, évaluées sur plusieurs critères, avec des implémentations GDScript et des recommandations d'ordre d'apprentissage.

---

## Tableau Comparatif des Mécaniques

| **Mécanique** | **Complexité** | **Impact Fun** | **Temps Implémentation** | **Potentiel Puzzle** | **Difficulté à Maîtriser** |
|---|:---:|:---:|:---:|:---:|:---:|
| Saut variable | Très faible | Élevé | 5 min | Bas | Très facile |
| Double saut | Très faible | Élevé | 10 min | Bas | Très facile |
| Wallslide/Wall jump | Moyen | Très élevé | 30 min | Moyen | Moyen |
| Plateforme mobile | Faible | Moyen | 15 min | Moyen | Facile |
| Plateforme destructible | Faible | Moyen | 20 min | Bas | Facile |
| Dash | Moyen | Très élevé | 25 min | Moyen | Moyen |
| Gravité inversible | Moyen | Très élevé | 40 min | Très élevé | Moyen-difficile |
| Zones de friction | Faible | Moyen | 20 min | Moyen | Facile |
| Rebond/Trampoline | Très faible | Moyen-élevé | 10 min | Bas | Très facile |
| Systèmes de couches (shadow worlds) | Élevée | Très élevé | 60 min | Très élevé | Difficile |
| Construire/détruire plateforme | Moyen | Moyen-élevé | 30 min | Très élevé | Moyen |
| Téléporteurs | Très faible | Moyen | 15 min | Moyen | Très facile |
| Aimant/Répulsion | Moyen | Moyen-élevé | 35 min | Très élevé | Moyen |
| Slow-motion zones | Faible | Moyen | 20 min | Moyen | Facile |
| Ennemi basique (patrouille) | Faible | Moyen | 25 min | Bas | Facile |

---

## Important : Spécificités du Metroidvania

Un Metroidvania combine **exploration libre**, **progression gated** et **création progressive de puissances**. Contrairement à un platformer linéaire, tu dois penser :

1. **Progression verticale et horizontale** : Le joueur revient à des endroits déjà visités mais avec de nouvelles compétences
2. **Verrouillage de zones** : Certaines zones sont inaccessibles jusqu'à obtenir une capacité spécifique
3. **Secrets et exploration** : Encourager le joueur à explorer chaque recoin
4. **Carte interconnectée** : Zones qui se chevauchent et se rellient
5. **Collectibles importants** : Augmentations de vie, d'énergie, ou nouvelles capacités

---

## Mécaniques Core à Maîtriser D'Abord

### 1. Saut Variable
**Description** : La hauteur du saut dépend du temps où le joueur maintient le bouton saut.

**Pourquoi c'est important** : C'est la base d'un bon feel de platformer. Permet au joueur de contrôler précisément sa trajectoire.

**Implémentation GDScript** :
```gdscript
extends CharacterBody2D

const GRAVITY = 1000
const JUMP_FORCE = -500
const MAX_JUMP_TIME = 0.15  # temps max de montée en saut

var is_jumping = false
var jump_timer = 0.0

func _physics_process(delta):
    # Gravité
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    
    # Saut
    if Input.is_action_just_pressed("jump") and is_on_floor():
        is_jumping = true
        jump_timer = 0.0
        velocity.y = JUMP_FORCE
    
    if Input.is_action_pressed("jump") and is_jumping:
        jump_timer += delta
        if jump_timer < MAX_JUMP_TIME:
            velocity.y = JUMP_FORCE  # Force appliquée tant que bouton enfoncé
    
    if Input.is_action_just_released("jump"):
        is_jumping = false
    
    # Mouvement horizontal
    var input_dir = Input.get_axis("ui_left", "ui_right")
    velocity.x = input_dir * 300
    
    velocity = move_and_slide(velocity, Vector2.UP)
```

**Astuce** : Ajoute du **coyote time** pour que le joueur puisse sauter même s'il vient juste de quitter une plateforme (donne une sensation plus généreuse).

```gdscript
const COYOTE_TIME = 0.1
var coyote_timer = 0.0

func _physics_process(delta):
    if is_on_floor():
        coyote_timer = COYOTE_TIME
    else:
        coyote_timer -= delta
    
    # Saut possible si sur sol OU pendant coyote time
    if Input.is_action_just_pressed("jump") and coyote_timer > 0:
        velocity.y = JUMP_FORCE
        coyote_timer = 0
```

---

### 2. Double Saut
**Description** : Le joueur peut sauter une seconde fois en l'air, sans revenir au sol.

**Pourquoi** : Augmente la variété des trajectoires, permet un level design plus intéressant, et c'est très satisfaisant à contrôler.

**Implémentation GDScript** :
```gdscript
var jumps_available = 2
var max_jumps = 2

func _physics_process(delta):
    if is_on_floor():
        jumps_available = max_jumps
    
    if Input.is_action_just_pressed("jump"):
        if jumps_available > 0:
            velocity.y = JUMP_FORCE
            jumps_available -= 1
```

**Variante avancée** : Double saut qui donne moins de hauteur (différent du premier saut).

```gdscript
if Input.is_action_just_pressed("jump"):
    if jumps_available > 0:
        if jumps_available == 2:  # Premier saut
            velocity.y = JUMP_FORCE
        else:  # Deuxième saut
            velocity.y = JUMP_FORCE * 0.7  # 70% de la hauteur
        jumps_available -= 1
```

---

### 3. Plateforme Mobile (Sur Chemin)
**Description** : Une plateforme qui se déplace linéairement ou suit un chemin défini.

**Pourquoi** : Ajoute du rythme et du timing au niveau sans compliquer la mécanique joueur.

**Implémentation Simple (aller-retour)** :
```gdscript
extends Node2D

@export var speed = 200
@export var distance = 200  # Distance avant de faire demi-tour

var direction = 1
var traveled = 0.0

func _process(delta):
    position.x += direction * speed * delta
    traveled += speed * delta
    
    if traveled >= distance:
        direction *= -1
        traveled = 0.0
```

**Implémentation avec Tween (plus fluide)** :
```gdscript
extends Node2D

@export var speed = 200
@export var distance = 200

func _ready():
    animate_movement()

func animate_movement():
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_LINEAR)
    tween.set_loops()
    
    tween.tween_property(self, "position:x", position.x + distance, distance / speed)
    tween.tween_property(self, "position:x", position.x, distance / speed)
```

**Astuce** : Le joueur doit rester sur la plateforme. Ajoute le joueur comme enfant de la plateforme (ou gère sa position relative).

---

### 4. Wallslide et Wall Jump
**Description** : Le joueur peut glisser contre un mur et sauter depuis ce mur.

**Pourquoi** : Ouvre énormément de possibilités de level design. C'est une mécanique très satisfaisante qui augmente le contrôle du joueur.

**Implémentation GDScript** :
```gdscript
const WALL_DETECTION_DISTANCE = 20
const WALL_FRICTION = 0.95  # Ralentit la chute contre un mur
const WALL_JUMP_FORCE = Vector2(-400, -500)  # (horizontal, vertical)

var is_on_wall = false
var wall_normal = Vector2.ZERO

func _physics_process(delta):
    # Détection de mur via raycast
    var space_state = get_world_2d().direct_space_state
    var left_query = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(-WALL_DETECTION_DISTANCE, 0))
    var right_query = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(WALL_DETECTION_DISTANCE, 0))
    
    var left_hit = space_state.intersect_ray(left_query)
    var right_hit = space_state.intersect_ray(right_query)
    
    is_on_wall = (left_hit or right_hit) and not is_on_floor()
    
    if is_on_wall:
        wall_normal = -Vector2(1, 0) if left_hit else Vector2(1, 0)
        velocity.y *= WALL_FRICTION  # Ralentit la chute
    
    # Wall jump
    if Input.is_action_just_pressed("jump") and is_on_wall:
        var jump = WALL_JUMP_FORCE
        jump.x *= wall_normal.x
        velocity = jump
    
    velocity.y += GRAVITY * delta
    velocity = move_and_slide(velocity, Vector2.UP)
```

**Alternative plus simple** (détection avec Area2D) :
```gdscript
func _ready():
    $WallDetector.connect("body_entered", self, "_on_wall_detected")
    $WallDetector.connect("body_exited", self, "_on_wall_left")

var touching_wall = false

func _on_wall_detected(body):
    touching_wall = true

func _on_wall_left(body):
    touching_wall = false

func _physics_process(delta):
    if touching_wall and not is_on_floor():
        velocity.y *= WALL_FRICTION
    
    if Input.is_action_just_pressed("jump") and touching_wall:
        velocity = WALL_JUMP_FORCE
```

---

### 5. Dash (Accélération courte)
**Description** : Le joueur peut se propulser rapidement dans une direction, avec un cooldown.

**Pourquoi** : Très fun, permet d'éviter des obstacles, et donne une sensation de pouvoir.

**Implémentation GDScript** :
```gdscript
const DASH_SPEED = 1000
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 0.5

var can_dash = true
var is_dashing = false
var dash_timer = 0.0
var dash_direction = Vector2.ZERO

func _physics_process(delta):
    if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
        is_dashing = true
        dash_timer = DASH_DURATION
        dash_direction = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down")).normalized()
        if dash_direction == Vector2.ZERO:
            dash_direction = Vector2.RIGHT  # Direction par défaut
        can_dash = false
    
    if is_dashing:
        velocity = dash_direction * DASH_SPEED
        dash_timer -= delta
        if dash_timer <= 0:
            is_dashing = false
            yield(get_tree().create_timer(DASH_COOLDOWN), "timeout")
            can_dash = true
    else:
        # Gravité et mouvement normal
        velocity.y += GRAVITY * delta
        velocity.x = Input.get_axis("ui_left", "ui_right") * 300
    
    velocity = move_and_slide(velocity, Vector2.UP)
```

---

## Mécaniques Intermédiaires

### 6. Gravité Inversible
**Description** : Le joueur peut inverser la direction de la gravité (haut/bas/gauche/droite).

**Pourquoi** : Ouvre des puzzles complexes et uniques. Crée des moments "wow" quand bien exécuté.

**Complexité** : Moyen (demande quelques ajustements à la physique)

**Implémentation GDScript** :
```gdscript
const GRAVITY_STRENGTH = 1000
var gravity_vector = Vector2(0, 1)  # (0,1) = bas, (0,-1) = haut, (1,0) = droite, etc.

func _physics_process(delta):
    # Applique la gravité dans la direction définie
    velocity += gravity_vector * GRAVITY_STRENGTH * delta
    
    # Inversion de gravité
    if Input.is_action_just_pressed("flip_gravity"):
        gravity_vector = -gravity_vector
    
    # Saut orienté vers le "bas" (selon la direction de gravité)
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity -= gravity_vector.normalized() * 500
    
    # move_and_slide avec direction "up" adaptée
    var up_direction = -gravity_vector.normalized()
    velocity = move_and_slide(velocity, up_direction)
```

**Astuce visuelle** : Affiche une flèche qui indique la direction de gravité actuelle.

---

### 7. Plateforme Destructible
**Description** : Une plateforme disparaît après quelques secondes (ou au contact du joueur) et réapparaît.

**Pourquoi** : Ajoute de l'urgence et du timing.

**Implémentation GDScript** :
```gdscript
extends StaticBody2D

@export var destruction_delay = 1.0
@export var respawn_time = 3.0

var destroyed = false
var is_colliding = false

func _ready():
    $CollisionShape2D.connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
    if body.is_in_group("player") and not destroyed:
        trigger_destruction()

func trigger_destruction():
    destroyed = true
    $Sprite.modulate = Color.gray  # Feedback visuel
    yield(get_tree().create_timer(destruction_delay), "timeout")
    $CollisionShape2D.disabled = true
    $Sprite.hide()
    
    yield(get_tree().create_timer(respawn_time), "timeout")
    respawn()

func respawn():
    destroyed = false
    $CollisionShape2D.disabled = false
    $Sprite.show()
    $Sprite.modulate = Color.white
```

---

### 8. Zones de Friction Variable
**Description** : Des zones où le joueur glisse plus ou moins (surface glissante, collante, etc.).

**Pourquoi** : Change le ressenti du mouvement sans refonte complète.

**Implémentation GDScript** :
```gdscript
# Sur le joueur
var current_friction = 1.0
const NORMAL_FRICTION = 1.0
const ICE_FRICTION = 0.1
const SAND_FRICTION = 2.0

func _physics_process(delta):
    var input_dir = Input.get_axis("ui_left", "ui_right")
    velocity.x = lerp(velocity.x, input_dir * 300, 0.15 * current_friction)
    velocity.y += GRAVITY * delta
    velocity = move_and_slide(velocity, Vector2.UP)

# Zone de friction
extends Area2D

func _ready():
    connect("body_entered", self, "_on_body_entered")
    connect("body_exited", self, "_on_body_exited")

func _on_body_entered(body):
    if body.is_in_group("player"):
        body.current_friction = ICE_FRICTION

func _on_body_exited(body):
    if body.is_in_group("player"):
        body.current_friction = NORMAL_FRICTION
```

---

### 9. Rebond / Trampoline
**Description** : Une plateforme qui propulse le joueur très haut quand il la touche.

**Pourquoi** : Fun, satisfaisant, et crée des moments de maîtrise de timing.

**Implémentation GDScript** :
```gdscript
extends Area2D

@export var bounce_force = -1200
@export var bounce_scale = 1.5  # Agrandit temporairement pour feedback

func _ready():
    connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
    if body.is_in_group("player"):
        body.velocity.y = bounce_force
        
        # Feedback visuel
        var tween = create_tween()
        tween.tween_property(self, "scale", Vector2(1.2, 0.8), 0.1)
        tween.tween_property(self, "scale", Vector2(1, 1), 0.1)
```

---

### 10. Systèmes de Couches (Shadow Worlds)
**Description** : Deux dimensions parallèles. Le joueur peut basculer entre elles. Chaque couche a ses propres plateforme.

**Pourquoi** : Incroyablement riche pour le level design et les puzzles. Crée une complexité apparente sans surcharger mécaniquement.

**Complexité** : Élevée (mais faisable)

**Implémentation GDScript** (Approach simple avec CanvasLayer) :
```gdscript
extends Node2D

const LAYER_A = 0
const LAYER_B = 1

var current_layer = LAYER_A

func _ready():
    # Tous les objets de niveau doivent avoir un property "layer_id"
    for obj in get_tree().get_nodes_in_group("layered_platforms"):
        update_layer_visibility(obj)

func _process(delta):
    if Input.is_action_just_pressed("switch_layer"):
        current_layer = (current_layer + 1) % 2
        for obj in get_tree().get_nodes_in_group("layered_platforms"):
            update_layer_visibility(obj)

func update_layer_visibility(obj):
    if obj.layer_id == current_layer:
        obj.visible = true
        obj.get_node("CollisionShape2D").disabled = false
    else:
        obj.visible = false
        obj.get_node("CollisionShape2D").disabled = true

# Dans chaque plateforme
extends StaticBody2D
@export var layer_id = 0
```

**Astuce visuelle** : Colorer différemment les plateforme de chaque couche (bleu pour couche A, rouge pour couche B).

---

### 11. Construire/Détruire Plateforme
**Description** : Le joueur crée ou détruit des plateforme en temps réel via des puzzles (switches, interactions).

**Pourquoi** : Excellent pour les puzzles. Engage le joueur à penser spatialement.

**Implémentation GDScript** :
```gdscript
# Plateforme conditionnelle
extends StaticBody2D

@export var switch_node_path: NodePath

var is_active = false

func _ready():
    var switch_node = get_node(switch_node_path)
    if switch_node:
        switch_node.connect("switched", self, "_on_switch_activated")
    
    # Initial state
    set_active(false)

func _on_switch_activated(new_state):
    set_active(new_state)

func set_active(active: bool):
    is_active = active
    $CollisionShape2D.disabled = not active
    $Sprite.modulate = Color.white if active else Color.gray
```

---



### Tableau Comparatif des Mécaniques Metroidvania

| **Mécanique** | **Complexité** | **Impact Fun** | **Temps Implémentation** | **Importance pour MV** |
|---|:---:|:---:|:---:|:---:|
| Portes verrouillées | Très faible | Moyen | 10 min | **Critique** |
| Collectibles/Upgrades | Très faible | Très élevé | 15 min | **Critique** |
| Capacités progressives | Faible | Très élevé | 25 min | **Critique** |
| Santé et dégâts | Très faible | Élevé | 15 min | **Critique** |
| Ennemis intelligents | Moyen | Élevé | 40 min | **Important** |
| Boss fights | Moyen-élevé | Très élevé | 60 min | **Important** |
| Checkpoints/Respawn | Très faible | Très élevé | 20 min | **Important** |
| Mini-carte | Faible | Moyen | 30 min | Accessoire |
| Énigmes (leviers/plaques) | Faible | Moyen-élevé | 25 min | **Important** |
| Plateforme destructible | Faible | Moyen | 20 min | Accessoire |
| Zones d'eau | Moyen | Moyen | 30 min | Accessoire |
| Téléporteurs | Très faible | Moyen | 20 min | **Important** |
| Munitions/Énergie | Faible | Moyen-élevé | 25 min | Accessoire |
| Secrets/Zones cachées | Très faible | Élevé | 15 min | **Important** |

---

### 12. Portes Verrouillées et Clés
**Description** : Le joueur ne peut pas passer une porte sans avoir la clé correspondante. Les clés sont des collectibles.

**Pourquoi** : C'est le pilier du design Metroidvania. Force l'exploration et gated progression.

**Implémentation GDScript** :
```gdscript
# Sur le joueur
var inventory = {
    "red_key": false,
    "blue_key": false,
    "green_key": false
}

# Sur la porte
extends StaticBody2D

@export var required_key = "red_key"
@export var is_open = false

func _ready():
    $CollisionShape2D.disabled = is_open
    $Sprite.modulate = Color.red if required_key == "red_key" else Color.blue

func _on_player_body_entered(body):
    if body.is_in_group("player"):
        if body.inventory[required_key]:
            open_door()
        else:
            print("Besoin de la clé : " + required_key)

func open_door():
    is_open = true
    $CollisionShape2D.disabled = true
    $Sprite.modulate = Color.gray
```

**Astuce** : Représente les clés par des formes distinctes (triangle rouge, carré bleu, etc.). Affiche dans l'interface quelles clés le joueur possède.

---

### 13. Collectibles et Augmentations (Upgrades)
**Description** : Le joueur récupère des éléments qui augmentent sa santé max, son énergie, ou lui donnent des capacités.

**Pourquoi** : La sensation de progression est centrale au Metroidvania. Chaque collectible doit faire sentir une vraie amélioration.

**Implémentation GDScript** :
```gdscript
# Classe de base pour collectible
extends Area2D

@export var upgrade_type = "health"  # "health", "energy", "damage"
@export var amount = 25

signal collected(type, amount)

func _ready():
    connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
    if body.is_in_group("player"):
        body.apply_upgrade(upgrade_type, amount)
        emit_signal("collected", upgrade_type, amount)
        queue_free()

# Sur le joueur
var max_health = 100
var current_health = 100
var max_energy = 50
var current_energy = 50

func apply_upgrade(type: String, amount: int):
    match type:
        "health":
            max_health += amount
            current_health = max_health
        "energy":
            max_energy += amount
            current_energy = max_energy
        "damage":
            attack_damage += amount
```

**Variante** : Orbes de santé/énergie qui restaurent au moment du collectage au lieu d'augmenter le max.

```gdscript
func _on_body_entered(body):
    if body.is_in_group("player"):
        body.current_health += amount
        queue_free()
```

---

### 14. Capacités Progressives (Power-ups)
**Description** : Le joueur acquiert de nouvelles compétences qui le rendent plus puissant et ouvrent de nouvelles zones.

**Pourquoi** : C'est la structure core du Metroidvania. Chaque capacité déverrouille une partie du monde.

**Exemples de capacités** :
- **Double Saut** → Peut accéder à des plateformes plus hautes
- **Wall Jump** → Peut escalader certains murs
- **Dash** → Peut traverser certains obstacles
- **Natation** → Peut se déplacer dans l'eau
- **Vol plané** → Peut descendre lentement
- **Tir énergétique** → Peut détruire certains murs/ennemi

**Implémentation GDScript** :
```gdscript
# Sur le joueur
var abilities = {
    "double_jump": false,
    "wall_jump": false,
    "dash": false,
    "grapple_hook": false,
    "ground_slam": false
}

func unlock_ability(ability_name: String):
    if ability_name in abilities:
        abilities[ability_name] = true
        print("Capacité débloquée : " + ability_name)
        emit_signal("ability_unlocked", ability_name)

# Exemple : le double saut ne fonctionne que si débloqué
func _physics_process(delta):
    if Input.is_action_just_pressed("jump"):
        if jumps_available > 0:
            if jumps_available == 2 and not abilities["double_jump"]:
                return  # Ne peut pas double sauter
            velocity.y = JUMP_FORCE
            jumps_available -= 1

# Dans une zone gated
extends Area2D

@export var required_ability = "double_jump"

func _ready():
    connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
    if body.is_in_group("player"):
        if not body.abilities[required_ability]:
            # Zone bloquée, affiche feedback
            $Sprite.modulate = Color.red
        else:
            # Zone accessible
            $Sprite.modulate = Color.green
```

---

### 15. Système de Santé et Dégâts
**Description** : Le joueur a une barre de santé. Les ennemis et piques font des dégâts.

**Pourquoi** : Crée des enjeux et du tension. Force à être prudent.

**Implémentation GDScript** :
```gdscript
# Sur le joueur
@export var max_health = 100
var current_health = 100

signal health_changed(new_health)
signal player_died

func take_damage(amount: int):
    current_health = max(0, current_health - amount)
    emit_signal("health_changed", current_health)
    
    if current_health <= 0:
        die()
    else:
        # Invulnérabilité temporaire
        invulnerable = true
        $Sprite.modulate = Color.red
        yield(get_tree().create_timer(0.5), "timeout")
        $Sprite.modulate = Color.white
        invulnerable = false

func heal(amount: int):
    current_health = min(max_health, current_health + amount)
    emit_signal("health_changed", current_health)

func die():
    emit_signal("player_died")
    get_tree().reload_current_scene()

# Sur les piques/obstacles
extends Area2D

@export var damage = 10

func _ready():
    connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
    if body.is_in_group("player") and not body.invulnerable:
        body.take_damage(damage)
```

---

### 16. Ennemis Intelligents (Patrouille et Poursuite)
**Description** : Les ennemis patrouillent, puis poursuivent le joueur s'il est détecté.

**Pourquoi** : Crée du danger dynamique et de l'exploration tactique.

**Implémentation GDScript** :
```gdscript
extends CharacterBody2D

@export var patrol_range = 200
@export var patrol_speed = 100
@export var chase_speed = 250
@export var detection_range = 150
@export var damage = 10

var direction = 1
var player_ref = null
var is_chasing = false

func _ready():
    add_to_group("enemy")
    player_ref = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
    velocity.y += 800 * delta  # Gravité
    
    if player_ref:
        var distance_to_player = global_position.distance_to(player_ref.global_position)
        
        if distance_to_player < detection_range:
            # Poursuite
            is_chasing = true
            if player_ref.global_position.x > global_position.x:
                velocity.x = chase_speed
            else:
                velocity.x = -chase_speed
        else:
            # Patrouille
            is_chasing = false
            velocity.x = patrol_speed * direction
            
            # Inverse direction aux limites
            if abs(global_position.x - get_parent().global_position.x) > patrol_range:
                direction *= -1
    
    velocity = move_and_slide(velocity, Vector2.UP)
    
    # Détection collision avec joueur
    for i in range(get_slide_collision_count()):
        var collision = get_slide_collision(i)
        if collision.get_collider().is_in_group("player"):
            collision.get_collider().take_damage(damage)
```

---

### 17. Boss Fights (Ennemi Avancé)
**Description** : Un ennemi plus puissant avec plusieurs phases et comportements variés.

**Pourquoi** : Crée des moments mémorables et défi d'apprentissage.

**Implémentation GDScript** :
```gdscript
extends CharacterBody2D

@export var max_health = 300
var current_health = 300
var phase = 1

signal boss_defeated
signal phase_changed(new_phase)

func _ready():
    add_to_group("boss")

func _physics_process(delta):
    match phase:
        1:
            phase1_behavior(delta)
        2:
            phase2_behavior(delta)
        3:
            phase3_behavior(delta)

func phase1_behavior(delta):
    # Phase simple : patrouille et attaque basique
    var player = get_tree().get_first_node_in_group("player")
    if player:
        velocity.x = 150 * sign(player.global_position.x - global_position.x)
    
    velocity.y += 800 * delta
    velocity = move_and_slide(velocity, Vector2.UP)

func phase2_behavior(delta):
    # Phase 2 : plus rapide, attaques multiples
    var player = get_tree().get_first_node_in_group("player")
    if player:
        velocity.x = 250 * sign(player.global_position.x - global_position.x)
    
    if is_on_floor():
        velocity.y = -400  # Saute régulièrement
    
    velocity.y += 800 * delta
    velocity = move_and_slide(velocity, Vector2.UP)

func phase3_behavior(delta):
    # Phase 3 : très agressif
    var player = get_tree().get_first_node_in_group("player")
    if player:
        velocity.x = 350 * sign(player.global_position.x - global_position.x)
        velocity.y = 350 * sign(player.global_position.y - global_position.y)

func take_damage(amount: int):
    current_health -= amount
    
    # Change de phase
    if current_health <= max_health * 0.66 and phase == 1:
        phase = 2
        emit_signal("phase_changed", 2)
    elif current_health <= max_health * 0.33 and phase == 2:
        phase = 3
        emit_signal("phase_changed", 3)
    
    if current_health <= 0:
        defeated()

func defeated():
    emit_signal("boss_defeated")
    queue_free()
```

---

### 18. Systèmes de Checkpoints et Sauvegarde
**Description** : Le joueur peut respawner à des checkpoints spécifiques au lieu du début du niveau.

**Pourquoi** : Essentiel pour les Metroidvania. Évite frustration si tuer au boss.

**Implémentation GDScript** :
```gdscript
# Checkpoint
extends Area2D

@export var checkpoint_id = 1

signal checkpoint_reached(id)

func _ready():
    connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
    if body.is_in_group("player"):
        emit_signal("checkpoint_reached", checkpoint_id)
        body.set_checkpoint(global_position)
        $Sprite.modulate = Color.green  # Feedback visuel

# Sur le joueur
var current_checkpoint = Vector2.ZERO

func set_checkpoint(position: Vector2):
    current_checkpoint = position
    print("Checkpoint sauvegardé à : " + str(position))

func die():
    global_position = current_checkpoint
    current_health = max_health
    invulnerable = true
    yield(get_tree().create_timer(1.0), "timeout")
    invulnerable = false
```

---

### 19. Cartes et Mini-carte
**Description** : Une interface montrant la disposition du niveau et les zones explorées.

**Pourquoi** : Essentiel pour l'exploration Metroidvania. Aide le joueur à se situer.

**Implémentation Simple avec CanvasLayer** :
```gdscript
# Mini-carte
extends Control

const TILE_SIZE = 32
const ROOM_SIZE = Vector2(320, 180)

var explored_rooms = {}
var player_ref = null

func _ready():
    player_ref = get_tree().get_first_node_in_group("player")

func _process(delta):
    update()

func _draw():
    # Draws all explored rooms
    for room_id in explored_rooms:
        var position = get_room_screen_position(room_id)
        var color = explored_rooms[room_id]
        draw_rect(Rect2(position, Vector2(16, 16)), color)
    
    # Draw player position
    if player_ref:
        var room = get_current_room(player_ref.global_position)
        var pos = get_room_screen_position(room)
        draw_circle(pos + Vector2(8, 8), 3, Color.yellow)

func mark_room_explored(room_id: String):
    explored_rooms[room_id] = Color.white

func get_current_room(position: Vector2) -> String:
    var room_x = int(position.x / ROOM_SIZE.x)
    var room_y = int(position.y / ROOM_SIZE.y)
    return "%d_%d" % [room_x, room_y]

func get_room_screen_position(room_id: String) -> Vector2:
    var parts = room_id.split("_")
    return Vector2(int(parts[0]) * 20, int(parts[1]) * 20)
```

---

### 20. Énigmes et Mécaniques Environnementales
**Description** : Objets interactifs (leviers, plaques de pression) qui ouvrent des portes ou changent l'environnement.

**Pourquoi** : Enrichit l'exploration et crée des puzzles.

**Implémentation GDScript** :
```gdscript
# Levier
extends Area2D

@export var target_door_path: NodePath
var is_activated = false

signal lever_activated

func _ready():
    connect("body_entered", self, "_on_body_entered")
    connect("body_exited", self, "_on_body_exited")

func _on_body_entered(body):
    if body.is_in_group("player") and Input.is_action_just_pressed("interact"):
        toggle_lever()

func toggle_lever():
    is_activated = !is_activated
    var target = get_node(target_door_path)
    if is_activated:
        target.open_door()
        $Sprite.modulate = Color.green
    else:
        target.close_door()
        $Sprite.modulate = Color.red
    emit_signal("lever_activated")

# Plaque de pression
extends Area2D

@export var target_door_path: NodePath
var bodies_on_plate = 0

func _ready():
    connect("body_entered", self, "_on_body_entered")
    connect("body_exited", self, "_on_body_exited")

func _on_body_entered(body):
    bodies_on_plate += 1
    if bodies_on_plate > 0:
        get_node(target_door_path).open_door()

func _on_body_exited(body):
    bodies_on_plate -= 1
    if bodies_on_plate <= 0:
        get_node(target_door_path).close_door()
```

---

### 21. Zones d'Eau et Mécanique de Natation
**Description** : Le joueur peut entrer dans l'eau et se déplacer différemment (flottabilité, vitesse réduite).

**Pourquoi** : Ajoute de la variété environnementale. Ouvre des zones inaccessibles sans compétence.

**Implémentation GDScript** :
```gdscript
# Zone d'eau
extends Area2D

@export var water_gravity = 300
@export var water_resistance = 0.15

var bodies_in_water = []

func _ready():
    connect("body_entered", self, "_on_body_entered")
    connect("body_exited", self, "_on_body_exited")

func _on_body_entered(body):
    if body.is_in_group("player"):
        bodies_in_water.append(body)
        body.in_water = true

func _on_body_exited(body):
    if body.is_in_group("player"):
        bodies_in_water.erase(body)
        body.in_water = false

# Sur le joueur
var in_water = false

func _physics_process(delta):
    if in_water:
        # Réduit la gravité
        velocity.y += water_gravity * delta
        # Réduit la vitesse horizontale
        velocity.x *= water_resistance
    else:
        velocity.y += GRAVITY * delta
```

---

### 22. Plateformes et Obstacles Destructibles
**Description** : Certains murs/plateforme ne peuvent être détruits que avec une capacité spécifique (tir énergétique, charge...).

**Pourquoi** : Verrouille des zones jusqu'à l'acquisition de compétences.

**Implémentation GDScript** :
```gdscript
extends StaticBody2D

@export var required_ability = "energy_shot"
@export var durability = 3  # Nombre de coups avant destruction
var current_durability = 3

func _ready():
    add_to_group("destructible")

func take_damage(damage_type: String, amount: int):
    if damage_type == required_ability:
        current_durability -= amount
        $Sprite.modulate.a = float(current_durability) / 3  # Fade out
        
        if current_durability <= 0:
            destroy()

func destroy():
    # Particules simples
    var particle_count = 5
    for i in range(particle_count):
        var particle = preload("res://scenes/particle.tscn").instantiate()
        particle.global_position = global_position
        get_parent().add_child(particle)
    
    queue_free()
```

---

### 23. Téléporteurs et Salles Multiples
**Description** : Systèmes de portes rapides entre zones, essentiels pour la navigation en Metroidvania.

**Pourquoi** : Réduit le backtracking frustrant et permet une meilleure exploration.

**Implémentation GDScript** :
```gdscript
# Porte de téléportation
extends Area2D

@export var destination_room: String  # Identifiant de la pièce cible
@export var spawn_position: Vector2

signal room_changed(new_room)

func _ready():
    connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
    if body.is_in_group("player"):
        # Transition
        $AnimationPlayer.play("fade_out")
        yield($AnimationPlayer, "animation_finished")
        
        body.global_position = spawn_position
        emit_signal("room_changed", destination_room)
        
        $AnimationPlayer.play("fade_in")
```

---

### 24. Système de Munitions/Énergie
**Description** : Le joueur a une barre d'énergie pour utiliser des capacités spéciales (tirs, dash, etc.).

**Pourquoi** : Limite l'usage des capacités puissantes, crée du rythme dans les combats.

**Implémentation GDScript** :
```gdscript
var max_energy = 100
var current_energy = 100
var energy_regen_rate = 20  # Points par seconde

signal energy_changed(new_energy)

func _physics_process(delta):
    # Régénération passive
    current_energy = min(max_energy, current_energy + energy_regen_rate * delta)
    emit_signal("energy_changed", current_energy)

func use_energy(amount: int) -> bool:
    if current_energy >= amount:
        current_energy -= amount
        emit_signal("energy_changed", current_energy)
        return true
    return false

func shoot():
    if use_energy(15):
        # Crée un projectile
        var projectile = preload("res://scenes/projectile.tscn").instantiate()
        projectile.global_position = global_position
        get_parent().add_child(projectile)
```

---

### 25. Secrets et Zones Cachées
**Description** : Zones non-évidentes accessibles seulement via exploration minutieuse ou certaines capacités.

**Pourquoi** : Récompense l'exploration approfondie. Crée des "aha!" moments.

**Implémentation GDScript** :
```gdscript
# Zone cachée (invisible jusqu'à une condition)
extends Area2D

@export var hidden_from_start = true
@export var reveal_on_ability = "reveal_secret"  # null si toujours visible

func _ready():
    if hidden_from_start:
        visible = false
        $CollisionShape2D.disabled = true

func _process(delta):
    var player = get_tree().get_first_node_in_group("player")
    if player and reveal_on_ability in player.abilities and player.abilities[reveal_on_ability]:
        if hidden_from_start:
            visible = true
            $CollisionShape2D.disabled = false
```

---

## Tableau des Priorités d'Apprentissage (Metroidvania)

### Phase 1 : Fondations Joueur (Session 1-2)
- Saut variable + Coyote time
- Double saut
- Mouvement horizontal fluide
- Système de santé et dégâts

**Pourquoi** : Base absolue pour un Metroidvania. Le joueur doit contrôler parfaitement son perso avant l'exploration.

### Phase 2 : Exploration et Progression (Session 3-4)
- Portes verrouillées et clés
- Collectibles et augmentations
- Capacités progressives (débloquage)
- Checkpoints et respawn

**Pourquoi** : C'est le cœur du Metroidvania. Sans ces systèmes, pas de progression.

### Phase 3 : Monde Vivant (Session 5-6)
- Ennemis intelligents (patrouille + poursuite)
- Plateformes mobiles
- Zones de friction variable
- Énigmes simples (leviers, plaques)

**Pourquoi** : Crée un monde réactif et intéressant. Ajoute de la difficulté progressive.

### Phase 4 : Contenus Avancés (Session 7-8)
- Wallslide + Wall jump
- Dash
- Zones d'eau et mécanique de natation
- Plateforme destructible (capacité)

**Pourquoi** : Ouvre de nouvelles zones et augmente la variété.

### Phase 5 : Système et Contenu Riche (Session 9+)
- Boss fights
- Systèmes de munitions/énergie
- Couches multiples (shadow worlds)
- Secrets et zones cachées
- Mini-carte
- Téléporteurs multi-salles

**Pourquoi** : Complexité et profondeur. Pour un Metroidvania complet.

---

## Recommandations de Structure

### Hiérarchie Recommandée pour ton Projet

```
res://
├── scenes/
│   ├── player/
│   │   ├── player.tscn
│   │   └── player.gd
│   ├── levels/
│   │   ├── level_01.tscn
│   │   ├── level_02.tscn
│   │   └── ...
│   └── objects/
│       ├── platform/
│       │   ├── static_platform.tscn
│       │   ├── moving_platform.tscn
│       │   ├── destructible_platform.tscn
│       │   └── bouncy_platform.tscn
│       ├── enemies/
│       │   └── basic_enemy.tscn
│       └── ui/
│           └── hud.tscn
├── scripts/
│   ├── player.gd
│   ├── platforms.gd
│   └── level_manager.gd
└── assets/
    └── (shapes basiques)
```

### Best Practices pour le Metroidvania

1. **Architecture en Salles** : Crée un `RoomManager` qui gère les transitions et la sauvegarde.
   ```gdscript
   class_name RoomManager
   extends Node
   
   var current_room = "room_1"
   var rooms = {}
   
   func load_room(room_name: String):
       if current_room in rooms:
           rooms[current_room].queue_free()
       current_room = room_name
       rooms[room_name] = load("res://scenes/rooms/" + room_name + ".tscn").instantiate()
       add_child(rooms[room_name])
   ```

2. **Arbre des Capacités** : Dessine un graphe des capacités et comment elles s'ouvrent.
   ```
   Double Saut → Wall Jump → Certaine zone haute
   Clé Rouge → Porte Rouge → Nouvelle zone
   Énergie → Tir Énergétique → Murs destructibles
   ```

3. **Sauvegarde Progressive** : Garde trace de ce que le joueur a débloqué et où il était.
   ```gdscript
   var save_data = {
       "last_checkpoint": current_checkpoint,
       "abilities": abilities,
       "keys": inventory,
       "health": current_health
   }
   
   func save_game():
       var file = File.new()
       file.open("user://savegame.json", File.WRITE)
       file.store_var(save_data)
   ```

4. **Design des Zones** : Chaque zone doit avoir un thème visuel distinct (même avec formes).
   - Zone 1 : Formes blanches
   - Zone 2 : Formes bleues
   - Zone 3 : Formes rouges
   - Etc.

5. **Feedback de Progression** : Le joueur doit *sentir* sa progression.
   - Augmentation de santé ? Affiche "+25 HP"
   - Nouvelle capacité ? Affiche un popup "DOUBLE SAUT DÉBLOQUÉ"
   - Clé trouvée ? Ajoute à l'interface de façon visible

6. **Éviter le Backtracking Frustrant** :
   - Ajoute des raccourcis après certains bosses
   - Utilise des portes à sens unique quand approprié
   - Crée des téléporteurs pour grandes distances

---

## Idées Pour une Démo Metroidvania (5 Salles)

### Salle 1 : Le Départ (Apprentissage)
- Plateforme statiques simples
- Ennemis très faibles
- Collectible de santé visible
- Objectif : maîtriser saut et mouvement
- **Aucun verrouillage** → Salle entièrement accessible

### Salle 2 : Porte à Clé
- Clé rouge au sol (à chercher)
- Porte rouge bloquant l'accès
- Quelques ennemis basiques
- Objectif : introduire concept clé + porte
- **Verrouillage** : besoin clé rouge

### Salle 3 : Double Saut Obligatoire
- Fossé trop large sans double saut
- Plateforme en hauteur nécessitant le double saut
- Capacité "Double Saut" trouvable dans la salle
- Objectif : débloquer et tester une capacité
- **Verrouillage** : besoin double saut pour la sortie

### Salle 4 : Monde Interconnecté
- Peut revenir à Salle 1 et 2, mais accéder à des zones cachées avec double saut
- Ennemi plus difficile
- Boss faible ou mini-boss
- Checkpoint
- Objectif : montrer que le monde s'ouvre avec les capacités
- **Verrouillage** : capacités précédentes + peut-être wall jump

### Salle 5 : Intégration Totale
- Mélange de tout : clés, capacités, énigmes
- Eau à traverser (besoin capacité natation trouvée avant)
- Boss final
- Objectif : montrer la progression
- **Verrouillage** : accumulation des capacités précédentes

---

## Astuce Finale : Le "Juicy" Factor

Même avec des formes simples, tu peux rendre ton jeu très satisfaisant :

- **Screenshake léger** au saut/impact
- **Couleurs vives** pour feedback
- **Timing des animations** (sauts qui prennent 0.3s plutôt que 0.1s paraît plus pro)
- **Particules** : petits cercles/triangles qui s'échappent
- **Contrôle du son** : beep saut, boop saut double, swoosh dash

Godot fait ça très bien nativement !

---

## Ressources Godot Utiles

- **Official Godot CharacterBody2D Docs** : https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html
- **Godot Tweens** : Pour animations fluides (`create_tween()`)
- **Signaux** : Le cœur du game design réactif dans Godot
- **CanvasLayer** : Pour les systèmes de couches

---

## Conclusion : Construire ton Metroidvania

Un Metroidvania c'est une **combinaison de plusieurs systèmes** qui travaillent ensemble :
- **Exploration** : monde interconnecté, secrets
- **Progression** : capacités qui déverrouillent zones
- **Combat** : ennemis et bosses comme enjeux
- **Puzzle** : énigmes environnementales
- **Ressenti** : collectibles, amélioration, checkpoints

### Ma Recommandation de Démarrage

1. **Semaine 1** : Crée un joueur solide (Phase 1 complète)
2. **Semaine 2** : Ajoute 2-3 salles avec portes/clés/capacités (Phase 2)
3. **Semaine 3-4** : Enrichis avec ennemis et énigmes (Phase 3)
4. **Semaine 5+** : Ajoute contenu avancé (Phase 4-5)

**N'essaie pas de faire le jeu complet d'un coup.** Les meilleurs Metroidvania sont construits par itération progressive. Chaque capacité débloque une nouvelle zone, chaque zone inspire une nouvelle capacité.

Commence petit, teste souvent, et laisse le level design émerger naturellement.

Bonne chance ! 🎮✨