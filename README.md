Bien sûr ! Voici une version améliorée de votre document en Markdown avec des logos et des explications plus détaillées :

# Dockerisator Fluent-Bit (En cours de développement)

![Docker](https://www.docker.com/sites/default/files/d8/2019-07/horizontal-logo-monochromatic-white.png)
![Fluent Bit](https://fluentbit.io/assets/img/logo.png)

## Statut

- 🔲 Dockerisator Fluent-Bit (pas encore fonctionnel)

## Problèmes

### Windows ne parvient pas à effectuer de résolution DNS via Pi-hole/AdGuard

Seuls les navigateurs fonctionnent correctement.

#### Solution

Configurer l'interface VirtualBox / VMware et y mettre l'IP de la VM AdGuard/Pi-hole en tant que DNS.

#### Étapes détaillées

1. **Ouvrir les paramètres de l'interface réseau :**
   - Allez dans les paramètres de votre interface réseau (VirtualBox ou VMware).

2. **Configurer les paramètres DNS :**
   - Ajoutez l'IP de votre VM AdGuard/Pi-hole comme serveur DNS principal.

3. **Redémarrer la machine :**
   - Redémarrez votre machine pour appliquer les modifications.

#### Exemple de configuration

- **IP de la VM AdGuard/Pi-hole :** `192.168.1.10`
- **Interface réseau :** `VirtualBox Host-Only Network`

#### Logos

![VirtualBox](https://www.virtualbox.org/graphics/vbox_logo1_160x160.png)
![VMware](https://www.vmware.com/content/dam/digitalmarketing/vmware/en/images/vmware-logo-white.png)

---

En suivant ces étapes, vous devriez être en mesure de résoudre les problèmes de résolution DNS sur Windows en utilisant Pi-hole ou AdGuard.
```

N'hésitez pas à ajuster les liens des logos ou les IP selon vos besoins spécifiques.
