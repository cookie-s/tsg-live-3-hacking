let meshes = [];

// シーン
const scene = new THREE.Scene();
// カメラ
const width = 800;
const height = 800;
const fov = 60;
const aspect = width / height;
const near = 1;
const far = 1000;
const camera = new THREE.PerspectiveCamera(fov, aspect, near, far);
camera.position.set(0, 0, 400);
// OrbitControls
const controls = new THREE.OrbitControls(camera);
const fontLoader = new THREE.FontLoader();
// レンダラー
const renderer = new THREE.WebGLRenderer();
renderer.setSize(width, height);
renderer.setClearColor(0x00517c);
document.getElementById("canvas").appendChild(renderer.domElement);
// ライト
const directionalLight = new THREE.DirectionalLight(0xffffff);
directionalLight.position.set(0, 0.7, 0.7);
scene.add(directionalLight);
// 環境光
const ambient = new THREE.AmbientLight(0x666666);
scene.add(ambient);

fontLoader.load('helvetiker_bold.typeface.json', font => {
    for(let i=0; i<3; i++) {
        const max = 100;
        const axisLength = max * 2;                     // 矢印の長さ
        const axisHeadLength = axisLength * 0.05;     // 矢印の頭の長さ
        const axisHeadWidth = axisHeadLength * 0.5;   // 矢印の頭の太さ
        const direction = new THREE.Vector3(i==0?1:0, i==1?1:0, i==2?1:0);  // 矢印の向き
        const start = new THREE.Vector3(i==0?-max:0, i==1?-max:0, i==2?-max:0);  // 矢印の向き
        const color = 0xff0000 >> (8*i);
        const axis = new THREE.ArrowHelper(direction, start, axisLength + axisHeadLength * 2, color, axisHeadLength, axisHeadWidth);
        scene.add(axis);

        const textGeometry = new THREE.TextGeometry('XYZ'[i], {
            font: font,
            size: axisLength / 20,
            height: 0,
            curveSegments: 0,
            bevelEnabled: true,
            bevelThickness: 0,
            bevelSize: 0,
            bevelSegments: 0
        });
        const textMaterial = new THREE.MeshPhongMaterial({color: color});
        const text = new THREE.Mesh(textGeometry, textMaterial);
        text.position.set(i==0?max+axisHeadLength*2:0, i==1?max+axisHeadLength*2:0, i==2?max+axisHeadLength*2:0);
        scene.add(text);
    }
});

function rgb2ycbcr(r, g, b) {
    return [
        0.299*r + 0.587*g + 0.114*b,
        -0.168736*r - 0.331264*g + 0.5*b,
        0.5*r - 0.418688*g - 0.081312*b,
    ];
}

function ycbcr2rgb(y, cb, cr) {
    return [
        y + 1.402*cr,
        y - 0.344136*cb - 0.714136*cr,
        y + 1.772*cb,
    ];
}

function main() {
    for(const mesh of meshes) {
        scene.remove(mesh);
    }
    meshes = [];

    const RGBVerts = [
        [0,0,0], [0,0,1], [0,1,0], [0,1,1], [1,0,0], [1,0,1], [1,1,0], [1,1,1],
    ].map(([x,y,z]) => [100*x,100*y,100*z]);

    const YCbCrVerts = [
        [0,0,0], [0,0,1], [0,1,0], [0,1,1], [1,0,0], [1,0,1], [1,1,0], [1,1,1],
    ].map(([y,cb,cr]) => [100*y,100*(cb-0.5),100*(cr-0.5)]);

    const vertss = [
        [RGBVerts, YCbCrVerts.map(x => ycbcr2rgb(...x))],
        [RGBVerts.map(x => rgb2ycbcr(...x)), YCbCrVerts],
    ][document.getElementById('mode').mode.value];
    for(const i in vertss) {
        const verts = vertss[i];

        const faces = [
            [0, 1, 3], [3, 2, 0],
            [5, 1, 0], [0, 4, 5],
            [0, 2, 6], [6, 4, 0],
            [4, 6, 7], [7, 5, 4],
            [7, 6, 2], [2, 3, 7],
            [1, 5, 7], [7, 3, 1],
        ];

        const geo = new THREE.Geometry();
        for(const v of verts) {
            geo.vertices.push(new THREE.Vector3(...v));
        }
        for(const f of faces) {
            geo.faces.push(new THREE.Face3(...f));
        }
        geo.computeFaceNormals();
        geo.computeVertexNormals();

        const mat = [new THREE.MeshBasicMaterial({color: 0xFF0000 >> (i*8), transparent: true, opacity: 0.3, depthTest: false})];
        const mesh = new THREE.Mesh(geo, mat);
        meshes.push(mesh);

        const wires = [
            [0, 1, 3, 2, 0],
            [5, 1, 0, 4, 5],
            [0, 2, 6, 4, 0],
            [4, 6, 7, 5, 4],
            [7, 6, 2, 3, 7],
            [1, 5, 7, 3, 1],
        ];
        const wireMat = new THREE.LineBasicMaterial({color: 0x000000, linewidth: 10});
        for(wire of wires) {
            const wireGeo = new THREE.Geometry() 
            for(v of wire) {
                wireGeo.vertices.push(new THREE.Vector3(...verts[v]));
            }
            const wireMesh = new THREE.Line(wireGeo, wireMat);
            meshes.push(wireMesh);
        }
    }
    for(const mesh of meshes) {
        scene.add(mesh);
    }
    render();
}

main();
function render() {
    requestAnimationFrame(render);
    controls.update();
    renderer.render(scene, camera);
}
