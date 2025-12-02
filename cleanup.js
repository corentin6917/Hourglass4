// Script de nettoyage pour Data Connect
const https = require('https');

const projectId = 'hourglass4';
const location = 'europe-west9';
const serviceId = 'hourglass4-main-service';
const connectorId = 'default';

async function executeQuery(operationName, variables = {}) {
    return new Promise((resolve, reject) => {
        const data = JSON.stringify({
            name: operationName,
            operationName: operationName,
            variables: variables
        });

        const options = {
            hostname: 'firebasedataconnect.googleapis.com',
            port: 443,
            path: `/v1beta/projects/${projectId}/locations/${location}/services/${serviceId}/connectors/${connectorId}:executeQuery`,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
        };

        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    resolve(JSON.parse(body));
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${body}`));
                }
            });
        });

        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

async function executeMutation(operationName, variables = {}) {
    return new Promise((resolve, reject) => {
        const data = JSON.stringify({
            name: operationName,
            operationName: operationName,
            variables: variables
        });

        const options = {
            hostname: 'firebasedataconnect.googleapis.com',
            port: 443,
            path: `/v1beta/projects/${projectId}/locations/${location}/services/${serviceId}/connectors/${connectorId}:executeMutation`,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
        };

        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    resolve(JSON.parse(body));
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${body}`));
                }
            });
        });

        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

async function cleanup() {
    console.log('🧹 Démarrage du nettoyage...\n');

    try {
        // Lister tous les utilisateurs
        console.log('📋 Récupération des utilisateurs...');
        const result = await executeQuery('ListAllUsers');
        const users = result.data?.users || [];

        console.log(`✅ Trouvé ${users.length} utilisateurs:\n`);
        users.forEach(u => console.log(`  - ${u.username} (${u.email})`));

        if (users.length === 0) {
            console.log('\nℹ️  Aucun utilisateur à supprimer.');
            return;
        }

        // Supprimer chaque utilisateur (les friendships seront supprimées automatiquement avec CASCADE)
        console.log('\n🗑️  Suppression...');
        for (const user of users) {
            try {
                await executeMutation('DeleteUserByUsername', { username: user.username });
                console.log(`  ✅ Supprimé: ${user.username}`);
            } catch (error) {
                console.log(`  ❌ Erreur pour ${user.username}: ${error.message}`);
            }
        }

        console.log('\n✨ Nettoyage terminé!');
        console.log('\n💡 Tu peux maintenant créer de nouveaux comptes corentin1 et corentin2 !');

    } catch (error) {
        console.error(`\n❌ Erreur: ${error.message}`);
        process.exit(1);
    }
}

cleanup();
